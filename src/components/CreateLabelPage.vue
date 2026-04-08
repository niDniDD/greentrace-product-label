<template>
  <div class="label-root min-vh-100 py-3">
    <div class="container px-2" style="max-width: 720px;">
      <section class="card border-0 shadow-sm rounded-4 mb-3">
        <div class="card-body py-3 px-3">
          <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3 mb-3">
            <div>
              <h1 class="h5 fw-bold text-success mb-1">สร้างฉลากใหม่ / ฉลากผัก</h1>
              <p class="small text-muted mb-0">กรอกข้อมูลสินค้า, ผัก, วันปลูก และ batch เพื่อบันทึกลง Supabase</p>
            </div>
            <div class="d-flex flex-wrap gap-2">
              <a href="/?view=vegetables" class="btn btn-success rounded-3">ดูฉลากผัก</a>
              <a href="/?view=list" class="btn btn-outline-success rounded-3">ดูรายการทั้งหมด</a>
            </div>
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
              <label for="labelType" class="form-label small fw-semibold">ประเภทฉลาก</label>
              <select id="labelType" v-model="labelType" class="form-select">
                <option v-for="option in labelTypeOptions" :key="option.value" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
            </div>

            <div class="col-12 col-md-6">
              <label for="productName" class="form-label small fw-semibold">{{ currentTypeCopy.nameLabel }}</label>
              <input
                id="productName"
                v-model="productName"
                class="form-control"
                list="productNameSuggestions"
                :placeholder="currentTypeCopy.namePlaceholder"
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
              <label for="plantingDate" class="form-label small fw-semibold">{{ currentTypeCopy.primaryDateLabel }}</label>
              <input id="plantingDate" v-model="plantingDate" type="date" class="form-control" />
            </div>

            <div class="col-12 col-md-6">
              <label for="expiryDate" class="form-label small fw-semibold">{{ currentTypeCopy.expiryDateLabel }}</label>
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
              <label for="compositionText" class="form-label small fw-semibold">{{ currentTypeCopy.infoLabel }}</label>
              <textarea
                id="compositionText"
                v-model="compositionText"
                class="form-control"
                rows="4"
                :placeholder="currentTypeCopy.infoPlaceholder"
              ></textarea>
            </div>

            <div class="col-12 col-md-6">
              <label for="benefitsText" class="form-label small fw-semibold">{{ currentTypeCopy.benefitsLabel }}</label>
              <textarea
                id="benefitsText"
                v-model="benefitsText"
                class="form-control"
                rows="4"
                placeholder="กรอก 1 บรรทัดต่อ 1 ข้อ"
              ></textarea>
            </div>

            <div class="col-12 col-md-6">
              <label for="instructionsText" class="form-label small fw-semibold">{{ currentTypeCopy.instructionsLabel }}</label>
              <textarea
                id="instructionsText"
                v-model="instructionsText"
                class="form-control"
                rows="4"
                :placeholder="currentTypeCopy.instructionsPlaceholder"
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
import { computed, onMounted, ref } from 'vue'
import { supabase } from '../lib/supabase.js'

const existingProducts = ref([])
const labelType = ref('vegetable')
const productName = ref('')
const productDescription = ref('')
const batchNumber = ref('')
const plantingDate = ref('')
const expiryDate = ref('')
const status = ref('active')
const compositionText = ref('')
const benefitsText = ref('')
const instructionsText = ref('')
const isSubmitting = ref(false)
const alertMessage = ref('')
const alertType = ref('success')
const createdBatchNumber = ref('')

const labelTypeOptions = [
  { value: 'vegetable', label: 'ผัก' },
  { value: 'fertilizer', label: 'ปุ๋ย' },
  { value: 'other', label: 'ฉลากทั่วไป' },
]

const labelTypeCopyMap = {
  vegetable: {
    nameLabel: 'ชนิดผัก / สินค้าเกษตร',
    namePlaceholder: 'เช่น ผักสลัดกรีนโอ๊ค',
    primaryDateLabel: 'วันปลูก',
    expiryDateLabel: 'วันเก็บเกี่ยว / วันหมดอายุ',
    infoLabel: 'ข้อมูลสำคัญของผัก / ส่วนประกอบ',
    infoPlaceholder: 'กรอกได้ 2 แบบ\n1) ข้อความสั้น 1 บรรทัดต่อ 1 ข้อ เช่น ปลูกในโรงเรือนอินทรีย์\n2) แบบ หัวข้อ | ค่า | รายละเอียด เช่น สีใบ | เขียวสด | เหมาะสำหรับเก็บเกี่ยวสด',
    benefitsLabel: 'ประโยชน์ของผัก',
    instructionsLabel: 'คำแนะนำเพิ่มเติม',
    instructionsPlaceholder: 'กรอก 1 บรรทัดต่อ 1 คำแนะนำ เช่น ควรเก็บในอุณหภูมิเย็น',
    typeDetail: 'ฉลากผัก',
  },
  fertilizer: {
    nameLabel: 'ชื่อปุ๋ย / สูตรปุ๋ย',
    namePlaceholder: 'เช่น ปุ๋ยน้ำชีวภาพสูตรเร่งใบ',
    primaryDateLabel: 'วันผลิต',
    expiryDateLabel: 'วันหมดอายุ',
    infoLabel: 'ส่วนประกอบ / ข้อมูลสำคัญ',
    infoPlaceholder: 'กรอก 1 บรรทัดต่อ 1 รายการ เช่น NPK | 16-16-16 | ช่วยบำรุงต้นและใบ',
    benefitsLabel: 'สรรพคุณ',
    instructionsLabel: 'วิธีใช้',
    instructionsPlaceholder: 'กรอก 1 บรรทัดต่อ 1 ขั้นตอนการใช้',
    typeDetail: 'ฉลากปุ๋ย',
  },
  other: {
    nameLabel: 'ชื่อฉลาก / รายการ',
    namePlaceholder: 'เช่น วัตถุดิบโรงเรือน',
    primaryDateLabel: 'วันที่อ้างอิง',
    expiryDateLabel: 'วันสิ้นสุด / วันหมดอายุ',
    infoLabel: 'ข้อมูลสำคัญ',
    infoPlaceholder: 'กรอก 1 บรรทัดต่อ 1 รายการของข้อมูลสำคัญ',
    benefitsLabel: 'จุดเด่น',
    instructionsLabel: 'คำแนะนำ',
    instructionsPlaceholder: 'กรอก 1 บรรทัดต่อ 1 คำแนะนำ',
    typeDetail: 'ฉลากทั่วไป',
  },
}

const currentTypeCopy = computed(() => labelTypeCopyMap[labelType.value] || labelTypeCopyMap.other)

const parseLines = (value) => {
  return value
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean)
}

const parseComposition = (value) => {
  return parseLines(value)
    .map((line) => {
      const parts = line.split('|').map((part) => part.trim())
      const [name = '', ratio = '', ...detailParts] = parts

      if (parts.length === 1) {
        return {
          name: 'ข้อมูลสำคัญ',
          ratio: '-',
          detail: name || 'ไม่ระบุรายละเอียด',
        }
      }

      return {
        name: name || 'ข้อมูลสำคัญ',
        ratio: ratio || '-',
        detail: detailParts.join(' | ') || name || 'ไม่ระบุรายละเอียด',
      }
    })
    .filter(Boolean)
}

const fetchProductSuggestions = async () => {
  const { data } = await supabase.from('products').select('name').order('name', { ascending: true })
  existingProducts.value = (data || []).map((item) => item.name)
}

const resetForm = () => {
  labelType.value = 'vegetable'
  productName.value = ''
  productDescription.value = ''
  batchNumber.value = ''
  plantingDate.value = ''
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

  const compositionItems = parseComposition(compositionText.value)

  compositionItems.unshift({
    name: 'ประเภทฉลาก',
    ratio: labelType.value,
    detail: currentTypeCopy.value.typeDetail,
  })

  if (plantingDate.value) {
    compositionItems.splice(1, 0, {
      name: currentTypeCopy.value.primaryDateLabel,
      ratio: plantingDate.value,
      detail: `วันที่อ้างอิงของ${currentTypeCopy.value.typeDetail}`,
    })
  }

  const { error: batchInsertError } = await supabase.from('batches').insert([
    {
      product_id: productId,
      batch_number: cleanBatchNumber,
      expiry_date: expiryDate.value,
      composition: compositionItems.length > 0 ? compositionItems : [{ name: 'รายละเอียดล็อต', ratio: '-', detail: cleanDescription || 'ไม่มีรายละเอียดเพิ่มเติม' }],
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
