<template>
  <div>
    <nav class="app-nav border-bottom bg-white sticky-top">
      <div class="container py-3 px-2" style="max-width: 760px;">
        <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-2">
          <div>
            <h1 class="h5 fw-bold text-success mb-1">GreenTrace Label Center</h1>
            <p class="small text-muted mb-0">จัดการฉลาก, QR และข้อมูลล็อตจากหน้าเดียว</p>
          </div>

          <div class="d-flex flex-wrap gap-2">
            <a href="/?view=vegetables" :class="['btn btn-sm rounded-3', currentView === 'vegetables' ? 'btn-success' : 'btn-outline-success']">
              ฉลากผัก
            </a>
            <a href="/?view=list" :class="['btn btn-sm rounded-3', currentView === 'list' ? 'btn-success' : 'btn-outline-success']">
              รายการฉลาก
            </a>
            <a href="/?view=create" :class="['btn btn-sm rounded-3', currentView === 'create' ? 'btn-success' : 'btn-outline-success']">
              สร้างฉลากใหม่
            </a>
            <a :href="defaultLabelHref" :class="['btn btn-sm rounded-3', currentView === 'label' ? 'btn-success' : 'btn-outline-success']">
              หน้า Landing
            </a>
          </div>
        </div>
      </div>
    </nav>

    <VegetableCatalogPage v-if="currentView === 'vegetables'" />
    <LabelListPage v-else-if="currentView === 'list'" />
    <CreateLabelPage v-else-if="currentView === 'create'" />
    <ProductLabelMobile v-else />
  </div>
</template>

<script setup>
import CreateLabelPage from './components/CreateLabelPage.vue'
import LabelListPage from './components/LabelListPage.vue'
import ProductLabelMobile from './components/ProductLabelMobile.vue'
import VegetableCatalogPage from './components/VegetableCatalogPage.vue'

const searchParams = new URLSearchParams(window.location.search)
const currentView = searchParams.get('view') || (searchParams.get('batch') ? 'label' : 'list')
const defaultBatch = searchParams.get('batch')?.trim() || 'BR-240406-01'
const defaultLabelHref = `/?batch=${encodeURIComponent(defaultBatch)}`
</script>

<style scoped>
.app-nav {
  z-index: 1000;
}
</style>
