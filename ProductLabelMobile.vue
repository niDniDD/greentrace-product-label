<template>
  <div class="label-root bg-light min-vh-100 py-3">
    <div class="container px-2" style="max-width: 420px;">
      <div v-if="loading" class="text-center py-5">
        <div class="spinner-border text-success" role="status">
          <span class="visually-hidden">Loading...</span>
        </div>
        <p class="mt-3 small text-muted">กำลังโหลดฉลาก...</p>
      </div>

      <div v-else-if="error" class="alert alert-danger" role="alert">
        {{ error }}
      </div>

      <div v-else>
        <header class="card border-0 shadow-sm rounded-4 mb-3" aria-label="Product label header">
          <div class="card-body py-3 px-3">
            <div class="d-flex justify-content-between align-items-start mb-3 gap-2">
              <div>
                <p class="text-uppercase small mb-1 text-muted">ชื่อสินค้า</p>
                <h1 class="h5 fw-bold mb-0 text-success">{{ product.product.name }}</h1>
              </div>
              <span class="badge expiry-badge text-uppercase">หมดอายุ {{ product.expiry_date }}</span>
            </div>

            <p class="mb-1 text-muted">Batch No. <strong>{{ product.batch_number }}</strong></p>
            <p class="mb-1 small text-muted">อัปเดตล่าสุด {{ product.updated_at }}</p>
            <div class="alert alert-warning py-2 px-3 mt-3 mb-0" role="status">
              <strong>สำคัญ:</strong> ตรวจสอบวันหมดอายุก่อนใช้งานทุกครั้ง
            </div>
          </div>
        </header>

        <section class="card border-0 shadow-sm rounded-4 mb-3" aria-labelledby="composition-heading">
          <div class="card-body py-3 px-3">
            <div class="mb-2">
              <h2 id="composition-heading" class="h6 mb-0 text-success">ส่วนประกอบหลัก</h2>
              <p class="small text-muted mb-0">ข้อมูลทางเทคนิคที่ทีมฟาร์มต้องรู้</p>
            </div>
            <ul class="list-group list-group-flush mb-0">
              <li
                v-for="(item, index) in product.composition"
                :key="index"
                class="list-group-item px-0 py-2 border-0"
              >
                <div class="d-flex justify-content-between align-items-center">
                  <span class="fw-semibold">{{ item.name }}</span>
                  <span class="text-muted small">{{ item.ratio }}</span>
                </div>
                <span class="d-block text-muted small">{{ item.detail }}</span>
              </li>
            </ul>
          </div>
        </section>

        <section class="card border-0 shadow-sm rounded-4 mb-3" aria-labelledby="benefits-heading">
          <div class="card-body py-3 px-3">
            <div class="mb-2">
              <h2 id="benefits-heading" class="h6 mb-0 text-success">สรรพคุณ</h2>
            </div>
            <ul class="list-unstyled mb-0">
              <li
                v-for="(benefit, index) in product.benefits"
                :key="index"
                class="mb-2 d-flex gap-2 align-items-start"
              >
                <span class="bullet"></span>
                <span class="text-muted">{{ benefit }}</span>
              </li>
            </ul>
          </div>
        </section>

        <section class="card border-0 shadow-sm rounded-4 mb-3" aria-labelledby="instruction-heading">
          <div class="card-body py-3 px-3">
            <div class="mb-2">
              <h2 id="instruction-heading" class="h6 mb-0 text-success">วิธีใช้</h2>
            </div>
            <ol class="instruction-list ps-3 mb-0">
              <li v-for="(step, index) in product.instructions" :key="index" class="mb-2">
                <span class="step-index">{{ index + 1 }}</span>
                <span class="instruction-text">{{ step }}</span>
              </li>
            </ol>
          </div>
        </section>

        <div class="d-grid gap-2 mb-3">
          <button
            type="button"
            class="btn btn-warning btn-lg rounded-4"
            aria-expanded="false"
            @click="toggleReportIssue"
          >
            แจ้งปัญหาในล็อตนี้
          </button>
        </div>

        <div v-if="showReportIssue" class="card border-0 shadow-sm rounded-4 mb-3">
          <div class="card-body py-3 px-3">
            <div class="mb-3">
              <h2 class="h6 text-success mb-1">รายละเอียดปัญหา</h2>
              <p class="small text-muted mb-2">เลือกประเภทปัญหาและอธิบายสั้นๆ เพื่อทีมปฏิบัติการ</p>
            </div>

            <div class="mb-3">
              <label class="form-label small fw-semibold" for="issueType">ประเภทปัญหา</label>
              <select id="issueType" class="form-select" v-model="issueType">
                <option v-for="option in issueTypes" :key="option.value" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
            </div>

            <div class="mb-3">
              <label class="form-label small fw-semibold" for="issueDescription">รายละเอียด</label>
              <textarea
                id="issueDescription"
                v-model="issueText"
                class="form-control"
                rows="3"
                placeholder="ระบุปัญหา เช่น สีเปลี่ยน กลิ่นแปลก หรือฉลากไม่ชัด"
                aria-label="รายละเอียดปัญหา"
              ></textarea>
            </div>

            <div class="d-flex gap-2">
              <button type="button" class="btn btn-success btn-sm flex-fill" @click="submitIssue" :disabled="isSubmitting">
                {{ isSubmitting ? 'กำลังส่ง...' : 'ส่งเรื่องแจ้งปัญหา' }}
              </button>
              <button type="button" class="btn btn-outline-secondary btn-sm flex-fill" @click="resetReportForm">
                ยกเลิก
              </button>
            </div>
          </div>
        </div>

        <div v-if="alertMessage" class="toast-alert alert alert-success alert-dismissible fade show" role="alert">
          {{ alertMessage }}
          <button type="button" class="btn-close" aria-label="Close" @click="alertMessage = ''"></button>
        </div>

        <footer class="text-center small text-muted mt-3">
          <p class="mb-1">ข้อมูลภายในฟาร์มเพื่อการตรวจสอบ และใช้งานภาคสนาม</p>
          <p class="mb-0">รองรับการใช้งานในสภาพแสงจ้าและหน้าจอมือถือ</p>
        </footer>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../lib/supabase.js'

const batchNumber = new URLSearchParams(window.location.search).get('batch') || 'BR-240406-01'
const product = ref(null)
const loading = ref(true)
const error = ref('')
const showReportIssue = ref(false)
const issueText = ref('')
const issueType = ref('Quality')
const isSubmitting = ref(false)
const alertMessage = ref('')

const issueTypes = [
  { value: 'Quality', label: 'Quality - คุณภาพ' },
  { value: 'Label', label: 'Label - ฉลาก' },
  { value: 'Safety', label: 'Safety - ความปลอดภัย' },
]

const fetchLabel = async () => {
  loading.value = true
  error.value = ''

  const { data, error: fetchError } = await supabase
    .from('batches')
    .select(`*, product:products(id,name,description)`)
    .eq('batch_number', batchNumber)
    .single()

  if (fetchError) {
    error.value = fetchError.message
    loading.value = false
    return
  }

  product.value = data
  loading.value = false
}

const toggleReportIssue = () => {
  showReportIssue.value = !showReportIssue.value
  if (!showReportIssue.value) {
    issueText.value = ''
    issueType.value = 'Quality'
  }
}

const resetReportForm = () => {
  showReportIssue.value = false
  issueText.value = ''
  issueType.value = 'Quality'
}

const submitIssue = async () => {
  if (!issueText.value.trim()) {
    alertMessage.value = 'กรุณาระบุรายละเอียดปัญหาก่อนส่ง'
    return
  }

  if (!product.value?.id) {
    alertMessage.value = 'ไม่สามารถส่งข้อมูลได้ในขณะนี้'
    return
  }

  isSubmitting.value = true

  const { error: insertError } = await supabase.from('issues').insert([
    {
      batch_id: product.value.id,
      issue_type: issueType.value,
      description: issueText.value.trim(),
    },
  ])

  isSubmitting.value = false

  if (insertError) {
    alertMessage.value = `ไม่สามารถส่งเรื่องได้: ${insertError.message}`
    return
  }

  alertMessage.value = 'ระบบได้รับข้อมูลแล้ว ทีมปฏิบัติการจะตรวจสอบภายในไม่กี่นาที'
  issueText.value = ''
  showReportIssue.value = false
}

onMounted(fetchLabel)
</script>

<style scoped>
.label-root {
  background: #f7f7f5;
  color: #1a2f20;
}

.expiry-badge {
  background-color: #ff8c42;
  color: #102010;
  padding: 0.55rem 0.75rem;
  border-radius: 1.25rem;
  font-size: 0.8rem;
  font-weight: 700;
}

.bullet {
  width: 0.4rem;
  height: 0.4rem;
  min-width: 0.4rem;
  margin-top: 0.55rem;
  border-radius: 50%;
  background-color: #6b8f5d;
  flex-shrink: 0;
}

.instruction-list {
  counter-reset: step;
}

.instruction-list li {
  display: flex;
  gap: 0.75rem;
  align-items: flex-start;
}

.step-index {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 1.75rem;
  height: 1.75rem;
  border-radius: 50%;
  background-color: #dfe8da;
  color: #1a2f20;
  font-weight: 700;
}

.instruction-text {
  display: inline-block;
  color: #3c4b36;
}

.toast-alert {
  transition: transform 0.2s ease, opacity 0.2s ease;
}

@media (min-width: 576px) {
  .container {
    padding-left: 1rem;
    padding-right: 1rem;
  }
}
</style>
