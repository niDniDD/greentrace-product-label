<template>
  <div class="label-root min-vh-100 py-3">
    <div class="container px-2" style="max-width: 720px;">
      <section class="card border-0 shadow-sm rounded-4 mb-3">
        <div class="card-body py-3 px-3">
          <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3 mb-3">
            <div>
              <h1 class="h5 fw-bold text-success mb-1">สร้างฉลากใหม่</h1>
              <p class="small text-muted mb-0">กรอกข้อมูลสินค้าและ batch เพื่อบันทึกลง Supabase</p>
            </div>
            <a href="/?view=list" class="btn btn-outline-success rounded-3">ดูรายการทั้งหมด</a>
          </div>

          <div v-if="alertMessage" :class="['alert', alertType === 'success' ? 'alert-success' : 'alert-danger']" role="alert">
            <div>{{ alertMessage }}</div>
            <div v-if="createdBatchNumber" class="d-flex flex-wrap gap-2 mt-2">
              <a :href="`/?batch=${encodeURIComponent(createdBatchNumber)}`" class="btn btn-success btn-sm rounded-3">
                เปิดฉลากที่สร้าง
              </a>
              <a href="/?view=list" class="btn btn-outline-success btn-sm rounded-3">
                กลับไปดูรายการ
              </a>
            </div>
          </div>

          <form @submit.prevent="submitLabel" class="row g-3">
            <div class="col-12 col-md-6">
              <label for="productName" class="form-label small fw-semibold">ชื่อสินค้า</label>
              <input
                id="productName"
                v-model="productName"
                class="form-control"
                list="productNameSuggestions"
                placeholder="เช่น Green Boost"
                required
              />
              <datalist id="productNameSuggestions">
                <option v-for="name in existingProducts" :key="name" :value="name" />
              </datalist>
            </div>

            <div class="col-12 col-md-6">
              <label for="batchNumber" class="form-label small fw-semibold">Batch number</label>
              <input
                id="batchNumber"
                v-model="batchNumber"
                class="form-control"
                placeholder="เช่น BR-240406-02"
                required
              />
            </div>

            <div class="col-12 col-md-6">
              <label for="expiryDate" class="form-label small fw-semibold">วันหมดอายุ</label>
              <input id="expiryDate" v-model="expiryDate" type="date" class="form-control" required />
            </div>

            <div class="col-12 col-md-6">
              <label for="status" class="form-label small fw-semibold">สถานะ</label>
              <select id="status" v-model="status" class="form-select">
                <option value="active">active</option>
                <option value="hold">hold</option>
                <option value="expired">expired</option>
              </select>
            </div>

            <div class="col-12">
              <label for="productDescription" class="form-label small fw-semibold">รายละเอียดสินค้า</label>
              <textarea
                id="productDescription"
                v-model="productDescription"
                class="form-control"
                rows="2"
                placeholder="รายละเอียดสั้น ๆ ของสินค้า"
              ></textarea>
            </div>

            <div class="col-12">
              <label for="compositionText" class="form-label small fw-semibold">ส่วนประกอบหลัก</label>
              <textarea
                id="compositionText"
                v-model="compositionText"
                class="form-control"
                rows="4"
                placeholder="กรอก 1 บรรทัดต่อ 1 รายการ เช่น&#10;น้ำหมักชีวภาพ | 60% | ช่วยบำรุงดิน&#10;แร่ธาตุรวม | 40% | เสริมการเจริญเติบโต"
              ></textarea>
            </div>

            <div class="col-12 col-md-6">
              <label for="benefitsText" class="form-label small fw-semibold">สรรพคุณ</label>
              <textarea
                id="benefitsText"
                v-model="benefitsText"
                class="form-control"
                rows="4"
                placeholder="กรอก 1 บรรทัดต่อ 1 ข้อ"
              ></textarea>
            </div>

            <div class="col-12 col-md-6">
              <label for="instructionsText" class="form-label small fw-semibold">วิธีใช้</label>
              <textarea
                id="instructionsText"
                v-model="instructionsText"
                class="form-control"
                rows="4"
                placeholder="กรอก 1 บรรทัดต่อ 1 ขั้นตอน"
              ></textarea>
            </div>

            <div class="col-12 d-flex flex-wrap gap-2">
              <button type="submit" class="btn btn-success rounded-3" :disabled="isSubmitting">
                {{ isSubmitting ? 'กำลังบันทึก...' : 'บันทึกฉลากลง Supabase' }}
              </button>
              <button type="button" class="btn btn-outline-secondary rounded-3" @click="resetForm">
                ล้างฟอร์ม
              </button>
            </div>
          </form>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { supabase } from '../lib/supabase.js'

const existingProducts = ref([])
const productName = ref('')
const productDescription = ref('')
const batchNumber = ref('')
const expiryDate = ref('')
const status = ref('active')
const compositionText = ref('')
const benefitsText = ref('')
const instructionsText = ref('')
const isSubmitting = ref(false)
const alertMessage = ref('')
const alertType = ref('success')
const createdBatchNumber = ref('')

const parseLines = (value) => {
  return value
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean)
}

const parseComposition = (value) => {
  return parseLines(value).map((line) => {
    const [name = '', ratio = '', ...detailParts] = line.split('|').map((part) => part.trim())

    return {
      name,
      ratio: ratio || '-',
      detail: detailParts.join(' | ') || name || 'ไม่ระบุรายละเอียด',
    }
  })
}

const fetchProductSuggestions = async () => {
  const { data } = await supabase.from('products').select('name').order('name', { ascending: true })
  existingProducts.value = (data || []).map((item) => item.name)
}

const resetForm = () => {
  productName.value = ''
  productDescription.value = ''
  batchNumber.value = ''
  expiryDate.value = ''
  status.value = 'active'
  compositionText.value = ''
  benefitsText.value = ''
  instructionsText.value = ''
}

const submitLabel = async () => {
  alertMessage.value = ''
  createdBatchNumber.value = ''

  if (!productName.value.trim() || !batchNumber.value.trim() || !expiryDate.value) {
    alertType.value = 'error'
    alertMessage.value = 'กรุณากรอกชื่อสินค้า, batch number และวันหมดอายุให้ครบ'
    return
  }

  isSubmitting.value = true

  const cleanProductName = productName.value.trim()
  const cleanDescription = productDescription.value.trim()
  const cleanBatchNumber = batchNumber.value.trim()

  const { data: existingProduct, error: existingProductError } = await supabase
    .from('products')
    .select('id')
    .eq('name', cleanProductName)
    .maybeSingle()

  if (existingProductError) {
    isSubmitting.value = false
    alertType.value = 'error'
    alertMessage.value = `ค้นหาสินค้าไม่สำเร็จ: ${existingProductError.message}`
    return
  }

  let productId = existingProduct?.id

  if (!productId) {
    const { data: insertedProduct, error: productInsertError } = await supabase
      .from('products')
      .insert([
        {
          name: cleanProductName,
          description: cleanDescription,
        },
      ])
      .select('id')
      .single()

    if (productInsertError) {
      isSubmitting.value = false
      alertType.value = 'error'
      alertMessage.value = `บันทึกสินค้าไม่สำเร็จ: ${productInsertError.message}`
      return
    }

    productId = insertedProduct.id
  }

  const { error: batchInsertError } = await supabase.from('batches').insert([
    {
      product_id: productId,
      batch_number: cleanBatchNumber,
      expiry_date: expiryDate.value,
      composition: parseComposition(compositionText.value),
      benefits: parseLines(benefitsText.value),
      instructions: parseLines(instructionsText.value),
      status: status.value,
    },
  ])

  isSubmitting.value = false

  if (batchInsertError) {
    alertType.value = 'error'
    alertMessage.value = `บันทึก batch ไม่สำเร็จ: ${batchInsertError.message}`
    return
  }

  alertType.value = 'success'
  alertMessage.value = 'สร้างฉลากใหม่สำเร็จแล้ว'
  createdBatchNumber.value = cleanBatchNumber
  resetForm()
  fetchProductSuggestions()
}

onMounted(fetchProductSuggestions)
</script>

<style scoped>
.label-root {
  background: #f7f7f5;
}
</style>
