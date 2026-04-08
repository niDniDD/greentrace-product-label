<template>
  <div class="label-root min-vh-100 py-3">
    <div class="container px-2" style="max-width: 720px;">
      <div class="screen-only">
        <section class="card border-0 shadow-sm rounded-4 mb-3">
          <div class="card-body py-3 px-3">
            <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3">
              <div>
                <h1 class="h5 fw-bold text-success mb-1">รายการฉลากทั้งหมด</h1>
                <p class="small text-muted mb-0">ค้นหา batch, เปิดฉลาก และพิมพ์ QR ได้จากหน้านี้</p>
              </div>
              <a href="/?view=create" class="btn btn-success rounded-3">+ สร้างฉลากใหม่</a>
            </div>

            <div class="mt-3">
              <label for="searchBatch" class="form-label small fw-semibold">ค้นหา batch หรือชื่อสินค้า</label>
              <input
                id="searchBatch"
                v-model="searchTerm"
                type="text"
                class="form-control"
                placeholder="เช่น BR-240406-01 หรือชื่อสินค้า"
              />
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

        <section v-else class="card border-0 shadow-sm rounded-4 mb-3">
          <div class="card-body py-3 px-3">
            <div class="d-flex justify-content-between align-items-center mb-3">
              <h2 class="h6 text-success mb-0">ผลลัพธ์</h2>
              <span class="badge bg-success">{{ filteredBatches.length }} ฉลาก</span>
            </div>

            <div v-if="filteredBatches.length === 0" class="text-center text-muted small py-4">
              ไม่พบข้อมูลฉลากที่ค้นหา
            </div>

            <div v-else class="d-grid gap-3">
              <article
                v-for="batch in filteredBatches"
                :key="batch.id"
                class="border rounded-4 p-3 bg-white"
              >
                <div class="d-flex justify-content-between align-items-start gap-3 mb-2">
                  <div>
                    <h3 class="h6 fw-bold mb-1 text-success">{{ batch.product?.name || 'ไม่ระบุชื่อสินค้า' }}</h3>
                    <p class="small text-muted mb-1">Batch No. <strong>{{ batch.batch_number }}</strong></p>
                    <p class="small text-muted mb-0">หมดอายุ {{ batch.expiry_date }}</p>
                  </div>
                  <span class="badge text-uppercase" :class="statusClass(batch.status)">
                    {{ batch.status || 'active' }}
                  </span>
                </div>

                <p class="small text-muted mb-3">{{ batch.product?.description || 'ไม่มีรายละเอียดเพิ่มเติม' }}</p>

                <div class="d-flex flex-wrap gap-2">
                  <a :href="makeLabelHref(batch.batch_number)" class="btn btn-sm btn-success rounded-3">
                    เปิดฉลาก
                  </a>
                  <button type="button" class="btn btn-sm btn-outline-success rounded-3" @click="selectBatch(batch)">
                    ดู QR
                  </button>
                  <button type="button" class="btn btn-sm btn-outline-secondary rounded-3" @click="printQr(batch)">
                    พิมพ์ QR
                  </button>
                  <button type="button" class="btn btn-sm btn-outline-primary rounded-3" @click="copyLink(batch.batch_number)">
                    คัดลอกลิงก์
                  </button>
                </div>
              </article>
            </div>
          </div>
        </section>

        <section v-if="selectedBatch" class="card border-0 shadow-sm rounded-4 mb-3">
          <div class="card-body py-3 px-3 text-center">
            <h2 class="h6 text-success mb-1">QR สำหรับ {{ selectedBatch.batch_number }}</h2>
            <p class="small text-muted mb-3">สแกนเพื่อเปิดฉลากของล็อตนี้โดยตรง</p>
            <QRCodeGenerator :key="selectedBatch.batch_number" :url="makeLandingUrl(selectedBatch.batch_number)" />
            <div class="d-flex flex-wrap justify-content-center gap-2 mt-3">
              <a :href="makeLabelHref(selectedBatch.batch_number)" class="btn btn-success btn-sm rounded-3">
                เปิดฉลาก
              </a>
              <button type="button" class="btn btn-outline-secondary btn-sm rounded-3" @click="window.print()">
                พิมพ์ตอนนี้
              </button>
            </div>
          </div>
        </section>
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
const selectedBatch = ref(null)
const landingOrigin = import.meta.env.VITE_APP_LANDING_ORIGIN || window.location.origin

const fetchBatches = async () => {
  loading.value = true
  error.value = ''

  const { data, error: fetchError } = await supabase
    .from('batches')
    .select('id, batch_number, expiry_date, status, updated_at, product:products(name, description)')
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

const filteredBatches = computed(() => {
  const keyword = searchTerm.value.trim().toLowerCase()

  if (!keyword) {
    return batches.value
  }

  return batches.value.filter((batch) => {
    const haystack = [batch.batch_number, batch.status, batch.product?.name, batch.product?.description]
      .filter(Boolean)
      .join(' ')
      .toLowerCase()

    return haystack.includes(keyword)
  })
})

const makeLabelHref = (batchNumber) => `/?batch=${encodeURIComponent(batchNumber)}`
const makeLandingUrl = (batchNumber) => `${landingOrigin}/?batch=${encodeURIComponent(batchNumber)}`

const selectBatch = (batch) => {
  selectedBatch.value = batch
}

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
