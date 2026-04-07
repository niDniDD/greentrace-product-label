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
import { ref, onMounted } from 'vue'
import QRCode from 'qrcode'

const props = defineProps({
  url: {
    type: String,
    required: true,
  },
})

const qrSrc = ref('')

onMounted(async () => {
  qrSrc.value = await QRCode.toDataURL(props.url)
})
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