<template>
  <div class="label-root min-vh-100 py-3">
    <div class="container px-2" style="max-width: 760px;">
      <section class="card border-0 shadow-sm rounded-4 mb-3">
        <div class="card-body py-3 px-3">
          <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3 mb-3">
            <div>
              <h1 class="h5 fw-bold text-success mb-1">ฉลากผักและ QR รายล็อต</h1>
              <p class="small text-muted mb-0">ดูวันปลูก ประโยชน์ และเปิดหน้าแจ้งปัญหาของผักแต่ละชนิดได้ทันที</p>
            </div>
            <div class="d-flex flex-wrap gap-2">
              <a href="/?view=create" class="btn btn-success rounded-3">+ สร้างฉลากใหม่</a>
              <a href="/?view=list" class="btn btn-outline-success rounded-3">ดูรายการแบบรวม</a>
            </div>
          </div>

          <label for="vegetableSearch" class="form-label small fw-semibold">ค้นหาผักหรือ batch</label>
          <input
            id="vegetableSearch"
            v-model="searchTerm"
            type="text"
            class="form-control"
            placeholder="เช่น ผักสลัด, คะน้า หรือ BR-240406-01"
          />
        </div>
      </section>

      <section v-if="loading" class="card border-0 shadow-sm rounded-4 mb-3">
        <div class="card-body text-center py-4">
          <div class="spinner-border text-success" role="status">
            <span class="visually-hidden">Loading...</span>
          </div>
          <p class="small text-muted mt-2 mb-0">กำลังโหลดฉลากผัก...</p>
        </div>
      </section>

      <section v-else-if="error" class="alert alert-danger" role="alert">
        {{ error }}
      </section>

      <div v-else class="d-grid gap-3">
        <article
          v-for="batch in filteredBatches"
          :key="batch.id"
          class="card border-0 shadow-sm rounded-4"
        >
          <div class="card-body py-3 px-3">
            <div class="row g-3 align-items-center">
              <div class="col-12 col-md-7">
                <div class="d-flex justify-content-between align-items-start gap-2 mb-2">
                  <div>
                    <h2 class="h5 fw-bold text-success mb-1">{{ batch.product?.name || 'ไม่ระบุชื่อผัก' }}</h2>
                    <p class="small text-muted mb-1">Batch No. <strong>{{ batch.batch_number }}</strong></p>
                  </div>
                  <span class="badge text-uppercase" :class="statusClass(batch.status)">
                    {{ batch.status || 'active' }}
                  </span>
                </div>

                <p class="small mb-1"><strong>วันปลูก:</strong> {{ resolvePlantingDate(batch) }}</p>
                <p class="small mb-2"><strong>พร้อมเก็บ/หมดอายุ:</strong> {{ batch.expiry_date || '-' }}</p>
                <p class="small text-muted mb-3">{{ batch.product?.description || 'ยังไม่มีรายละเอียดเพิ่มเติมของผักชนิดนี้' }}</p>

                <div>
                  <h3 class="h6 text-success mb-2">ประโยชน์เด่น</h3>
                  <ul class="list-unstyled mb-3">
                    <li
                      v-for="(benefit, index) in getBenefits(batch)"
                      :key="`${batch.id}-benefit-${index}`"
                      class="small d-flex gap-2 align-items-start mb-1"
                    >
                      <span class="bullet"></span>
                      <span>{{ benefit }}</span>
                    </li>
                  </ul>
                </div>

                <div class="d-flex flex-wrap gap-2">
                  <a :href="makeLabelHref(batch.batch_number)" class="btn btn-success btn-sm rounded-3">
                    เปิดฉลาก
                  </a>
                  <a :href="makeIssueHref(batch.batch_number)" class="btn btn-warning btn-sm rounded-3">
                    แจ้งปัญหา
                  </a>
                  <button type="button" class="btn btn-outline-primary btn-sm rounded-3" @click="copyLink(batch.batch_number)">
                    คัดลอกลิงก์
                  </button>
                </div>
              </div>

              <div class="col-12 col-md-5">
                <div class="qr-panel text-center">
                  <p class="small text-muted mb-2">QR ของ {{ batch.product?.name || batch.batch_number }}</p>
                  <QRCodeGenerator :key="batch.batch_number" :url="makeLandingUrl(batch.batch_number)" />
                </div>
              </div>
            </div>
          </div>
        </article>

        <section v-if="filteredBatches.length === 0" class="card border-0 shadow-sm rounded-4">
          <div class="card-body text-center py-4 text-muted small">
            ไม่พบข้อมูลผักหรือ batch ที่ค้นหา
          </div>
        </section>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { supabase } from '../lib/supabase.js'
import QRCodeGenerator from './QRCodeGenerator.vue'

const batches = ref([])
const loading = ref(true)
const error = ref('')
const searchTerm = ref('')
const landingOrigin = import.meta.env.VITE_APP_LANDING_ORIGIN || window.location.origin

const fetchBatches = async () => {
  loading.value = true
  error.value = ''

  const { data, error: fetchError } = await supabase
    .from('batches')
    .select('id, batch_number, expiry_date, status, created_at, benefits, composition, product:products(name, description)')
    .order('created_at', { ascending: false })

  if (fetchError) {
    error.value = `โหลดฉลากผักไม่สำเร็จ: ${fetchError.message}`
    loading.value = false
    return
  }

  batches.value = data || []
  loading.value = false
}

const resolveLabelType = (batch) => {
  const compositionItems = Array.isArray(batch?.composition) ? batch.composition : []
  const typeItem = compositionItems.find((item) => `${item?.name || ''}`.includes('ประเภทฉลาก'))
  const rawType = `${typeItem?.ratio || typeItem?.detail || ''}`.trim().toLowerCase()

  if (rawType.includes('vegetable') || rawType.includes('ผัก')) {
    return 'vegetable'
  }

  if (compositionItems.some((item) => `${item?.name || ''}`.includes('วันปลูก'))) {
    return 'vegetable'
  }

  return 'fertilizer'
}

const filteredBatches = computed(() => {
  const keyword = searchTerm.value.trim().toLowerCase()
  const vegetableOnly = batches.value.filter((batch) => resolveLabelType(batch) === 'vegetable')

  if (!keyword) {
    return vegetableOnly
  }

  return vegetableOnly.filter((batch) => {
    const haystack = [batch.batch_number, batch.product?.name, batch.product?.description, ...(batch.benefits || [])]
      .filter(Boolean)
      .join(' ')
      .toLowerCase()

    return haystack.includes(keyword)
  })
})

const formatDateOnly = (value) => {
  if (!value) {
    return '-'
  }

  return new Date(value).toLocaleDateString('th-TH', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  })
}

const resolvePlantingDate = (batch) => {
  const compositionItems = Array.isArray(batch?.composition) ? batch.composition : []
  const plantingItem = compositionItems.find((item) => {
    const itemName = `${item?.name || ''}`
    return itemName.includes('วันปลูก') || itemName.includes('วันผลิต') || itemName.includes('วันที่อ้างอิง')
  })

  return plantingItem?.ratio || formatDateOnly(batch?.created_at)
}

const getBenefits = (batch) => {
  if (Array.isArray(batch?.benefits) && batch.benefits.length > 0) {
    return batch.benefits.slice(0, 3)
  }

  const description = batch?.product?.description?.trim()
  if (description) {
    return [description]
  }

  const compositionItems = Array.isArray(batch?.composition) ? batch.composition : []
  const details = compositionItems
    .filter((item) => {
      const itemName = `${item?.name || ''}`
      return !itemName.includes('วันปลูก') && !itemName.includes('วันผลิต') && !itemName.includes('วันที่อ้างอิง') && !itemName.includes('ประเภทฉลาก')
    })
    .map((item) => item?.detail || item?.name)
    .filter(Boolean)

  if (details.length > 0) {
    return details.slice(0, 3)
  }

  return ['ช่วยให้ทีมฟาร์มติดตามข้อมูลแปลงและการใช้งานได้ง่ายขึ้น']
}

const statusClass = (status) => {
  switch (status) {
    case 'expired':
      return 'bg-danger'
    case 'hold':
      return 'bg-warning text-dark'
    default:
      return 'bg-success'
  }
}

const makeLandingUrl = (batchNumber) => `${landingOrigin}/?batch=${encodeURIComponent(batchNumber)}`
const makeLabelHref = (batchNumber) => `/?batch=${encodeURIComponent(batchNumber)}`
const makeIssueHref = (batchNumber) => `/?batch=${encodeURIComponent(batchNumber)}&action=report`

const copyLink = async (batchNumber) => {
  const url = makeLandingUrl(batchNumber)

  try {
    await navigator.clipboard.writeText(url)
    window.alert('คัดลอกลิงก์ของฉลากผักเรียบร้อยแล้ว')
  } catch {
    window.alert(url)
  }
}

onMounted(fetchBatches)
</script>

<style scoped>
.label-root {
  background: #f7f7f5;
}

.qr-panel {
  background: #f8fbf7;
  border: 1px solid rgba(44, 100, 56, 0.12);
  border-radius: 1rem;
  padding: 0.75rem;
}

.bullet {
  width: 0.42rem;
  height: 0.42rem;
  min-width: 0.42rem;
  margin-top: 0.45rem;
  border-radius: 50%;
  background-color: #6b8f5d;
  flex-shrink: 0;
}
</style>
