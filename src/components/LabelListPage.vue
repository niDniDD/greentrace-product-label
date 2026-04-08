<template>
  <div class="label-root min-vh-100 py-3">
    <div class="container px-2" style="max-width: 760px;">
      <div class="screen-only">
        <section class="card border-0 shadow-sm rounded-4 mb-3">
          <div class="card-body py-3 px-3">
            <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3 mb-3">
              <div>
                <h1 class="h5 fw-bold text-success mb-1">รายการฉลากทั้งหมด</h1>
                <p class="small text-muted mb-0">ค้นหา batch, ดูสถานะ เปิดฉลาก และพิมพ์ QR ได้จากหน้านี้</p>
              </div>
              <div class="d-flex flex-wrap gap-2">
                <a href="/?view=create" class="btn btn-success rounded-3">+ สร้างฉลากใหม่</a>
                <a href="/?view=vegetables" class="btn btn-outline-success rounded-3">ดูฉลากผัก</a>
              </div>
            </div>

            <div class="row g-3">
              <div class="col-12 col-md-7">
                <label for="searchBatch" class="form-label small fw-semibold">ค้นหา batch หรือชื่อสินค้า</label>
                <input
                  id="searchBatch"
                  v-model="searchTerm"
                  type="text"
                  class="form-control"
                  placeholder="เช่น BR-240406-01 หรือชื่อสินค้า"
                />
              </div>

              <div class="col-12 col-md-5">
                <label for="labelMenu" class="form-label small fw-semibold">เมนูประเภทฉลาก</label>
                <select id="labelMenu" v-model="selectedType" class="form-select">
                  <option v-for="option in labelTypeOptions" :key="option.value" :value="option.value">
                    {{ option.label }}
                  </option>
                </select>
              </div>
            </div>
          </div>
        </section>

        <section v-if="loading" class="card border-0 shadow-sm rounded-4 mb-3">
          <div class="card-body text-center py-4">
            <div class="spinner-border text-success" role="status">
              <span class="visually-hidden">Loading...</span>
            </div>
            <p class="small text-muted mt-2 mb-0">กำลังโหลดรายการฉลาก...</p>
          </div>
        </section>

        <section v-else-if="error" class="alert alert-danger" role="alert">
          {{ error }}
        </section>

        <div v-else class="d-grid gap-3">
          <section class="card border-0 shadow-sm rounded-4 mb-0">
            <div class="card-body py-3 px-3">
              <div class="d-flex justify-content-between align-items-center">
                <h2 class="h6 text-success mb-0">ผลลัพธ์</h2>
                <span class="badge bg-success">{{ filteredBatches.length }} ฉลาก</span>
              </div>
            </div>
          </section>
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
                      <h3 class="h5 fw-bold text-success mb-1">{{ batch.product?.name || 'ไม่ระบุชื่อสินค้า' }}</h3>
                      <p class="small text-muted mb-1">Batch No. <strong>{{ batch.batch_number }}</strong></p>
                    </div>
                    <div class="d-flex flex-column align-items-end gap-1">
                      <span class="badge text-uppercase" :class="statusClass(batch.status)">
                        {{ batch.status || 'active' }}
                      </span>
                    </div>
                  </div>

                  <p class="small mb-1"><strong>{{ getPrimaryDateLabel(batch) }}:</strong> {{ resolvePrimaryDate(batch) }}</p>
                  <p class="small mb-2"><strong>{{ getExpiryDateLabel(batch) }}:</strong> {{ batch.expiry_date || '-' }}</p>
                  <p class="small text-muted mb-3">{{ batch.product?.description || 'ไม่มีรายละเอียดเพิ่มเติม' }}</p>

                  <div>
                    <h4 class="h6 text-success mb-2">ประโยชน์เด่น</h4>
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
                    <a :href="makeLabelHref(batch.batch_number)" class="btn btn-sm btn-success rounded-3">
                      เปิดฉลาก
                    </a>
                    <a :href="makeIssueHref(batch.batch_number)" class="btn btn-sm btn-warning rounded-3">
                      แจ้งปัญหา
                    </a>
                    <button type="button" class="btn btn-sm btn-outline-secondary rounded-3" @click="printQr(batch)">
                      พิมพ์ QR
                    </button>
                    <div class="d-inline-flex align-items-center gap-2">
                      <button type="button" class="btn btn-sm btn-outline-primary rounded-3" @click="copyLink(batch.batch_number)">
                        คัดลอกลิงก์
                      </button>
                      <span class="label-type-chip" :title="getLabelTypeLabel(batch)" :aria-label="getLabelTypeLabel(batch)">
                        {{ getLabelTypeIcon(batch) }}
                      </span>
                    </div>
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
              ไม่พบข้อมูลฉลากที่ค้นหา
            </div>
          </section>
        </div>
      </div>

      <section v-if="selectedBatch" class="print-only text-center">
        <h1 class="h5 fw-bold mb-2">{{ selectedBatch.product?.name || 'GreenTrace Label' }}</h1>
        <p class="mb-1">Batch No. {{ selectedBatch.batch_number }}</p>
        <p class="small text-muted mb-3">สแกนเพื่อเปิดหน้าฉลาก</p>
        <QRCodeGenerator :key="`print-${selectedBatch.batch_number}`" :url="makeLandingUrl(selectedBatch.batch_number)" />
      </section>
    </div>
  </div>
</template>

<script setup>
import { computed, nextTick, onMounted, ref } from 'vue'
import { supabase } from '../lib/supabase.js'
import QRCodeGenerator from './QRCodeGenerator.vue'

const batches = ref([])
const loading = ref(true)
const error = ref('')
const searchTerm = ref('')
const selectedType = ref('all')
const selectedBatch = ref(null)
const landingOrigin = import.meta.env.VITE_APP_LANDING_ORIGIN || window.location.origin

const fetchBatches = async () => {
  loading.value = true
  error.value = ''

  const { data, error: fetchError } = await supabase
    .from('batches')
    .select('id, batch_number, expiry_date, status, updated_at, created_at, benefits, composition, product:products(name, description)')
    .order('updated_at', { ascending: false })

  if (fetchError) {
    error.value = `โหลดรายการฉลากไม่สำเร็จ: ${fetchError.message}`
    loading.value = false
    return
  }

  batches.value = data || []
  selectedBatch.value = batches.value[0] || null
  loading.value = false
}

const resolveLabelType = (batch) => {
  const compositionItems = Array.isArray(batch?.composition) ? batch.composition : []
  const typeItem = compositionItems.find((item) => `${item?.name || ''}`.includes('ประเภทฉลาก'))
  const rawType = `${typeItem?.ratio || typeItem?.detail || ''}`.trim().toLowerCase()

  if (rawType.includes('vegetable') || rawType.includes('ผัก')) {
    return 'vegetable'
  }

  if (rawType.includes('fertilizer') || rawType.includes('ปุ๋ย')) {
    return 'fertilizer'
  }

  if (rawType.includes('other') || rawType.includes('ทั่วไป')) {
    return 'other'
  }

  if (compositionItems.some((item) => `${item?.name || ''}`.includes('วันปลูก'))) {
    return 'vegetable'
  }

  return 'fertilizer'
}

const labelTypeLabelMap = {
  all: 'ทั้งหมด',
  vegetable: 'ผัก',
  fertilizer: 'ปุ๋ย',
  other: 'อื่น ๆ',
}

const labelTypeOptions = computed(() => {
  const discoveredTypes = Array.from(new Set(batches.value.map((batch) => resolveLabelType(batch))))
  const orderedTypes = ['all', 'vegetable', 'fertilizer', ...discoveredTypes.filter((type) => !['vegetable', 'fertilizer'].includes(type))]

  return Array.from(new Set(orderedTypes)).map((value) => ({
    value,
    label: labelTypeLabelMap[value] || value,
  }))
})

const filteredBatches = computed(() => {
  const keyword = searchTerm.value.trim().toLowerCase()

  return batches.value.filter((batch) => {
    const matchesType = selectedType.value === 'all' || resolveLabelType(batch) === selectedType.value
    const haystack = [batch.batch_number, batch.status, batch.product?.name, batch.product?.description, ...(batch.benefits || [])]
      .filter(Boolean)
      .join(' ')
      .toLowerCase()
    const matchesKeyword = !keyword || haystack.includes(keyword)

    return matchesType && matchesKeyword
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

const getLabelTypeLabel = (batch) => labelTypeLabelMap[resolveLabelType(batch)] || resolveLabelType(batch)
const getLabelTypeIcon = (batch) => {
  switch (resolveLabelType(batch)) {
    case 'vegetable':
      return '🥬'
    case 'fertilizer':
      return '🧪'
    default:
      return '🏷️'
  }
}
const getPrimaryDateLabel = (batch) => (resolveLabelType(batch) === 'vegetable' ? 'วันปลูก' : 'วันผลิต')
const getExpiryDateLabel = (batch) => (resolveLabelType(batch) === 'vegetable' ? 'พร้อมเก็บ/หมดอายุ' : 'วันหมดอายุ')
const resolvePrimaryDate = (batch) => resolvePlantingDate(batch)

const getBenefits = (batch) => {
  if (Array.isArray(batch?.benefits) && batch.benefits.length > 0) {
    return batch.benefits.slice(0, 3)
  }

  return ['ช่วยให้ทีมฟาร์มติดตามล็อตและการใช้งานได้ง่ายขึ้น']
}

const makeLabelHref = (batchNumber) => `/?batch=${encodeURIComponent(batchNumber)}`
const makeLandingUrl = (batchNumber) => `${landingOrigin}/?batch=${encodeURIComponent(batchNumber)}`
const makeIssueHref = (batchNumber) => `/?batch=${encodeURIComponent(batchNumber)}&action=report`

const copyLink = async (batchNumber) => {
  const url = makeLandingUrl(batchNumber)

  try {
    await navigator.clipboard.writeText(url)
    window.alert('คัดลอกลิงก์เรียบร้อยแล้ว')
  } catch {
    window.alert(url)
  }
}

const printQr = async (batch) => {
  selectedBatch.value = batch
  await nextTick()
  window.setTimeout(() => window.print(), 350)
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

.label-type-chip {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 2rem;
  height: 2rem;
  padding: 0 0.45rem;
  border-radius: 999px;
  background: #eef7ee;
  border: 1px solid rgba(44, 100, 56, 0.16);
  font-size: 1rem;
  line-height: 1;
}

.print-only {
  display: none;
}

@media print {
  .screen-only {
    display: none !important;
  }

  .print-only {
    display: block;
    padding: 1rem;
  }
}
</style>
