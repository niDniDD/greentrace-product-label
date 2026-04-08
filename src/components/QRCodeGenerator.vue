<template>
  <div class="qr-container text-center">
    <p class="small text-muted mb-2">สแกนเพื่อเข้าไปดูฉลาก</p>
    <img v-if="qrSrc" :src="qrSrc" alt="QR code" class="img-fluid mx-auto" />
    <div v-else class="spinner-border text-success" role="status">
      <span class="visually-hidden">Loading...</span>
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import QRCode from 'qrcode'

const props = defineProps({
  url: {
    type: String,
    required: true,
  },
})

const qrSrc = ref('')

const generateQr = async (url) => {
  qrSrc.value = ''
  qrSrc.value = await QRCode.toDataURL(url)
}

watch(
  () => props.url,
  (newUrl) => {
    if (newUrl) {
      generateQr(newUrl)
    }
  },
  { immediate: true },
)
</script>

<style scoped>
.qr-container {
  max-width: 280px;
  margin: 0 auto;
}
img {
  width: 100%;
  border-radius: 1rem;
  background: #ffffff;
  padding: 0.5rem;
}
</style>