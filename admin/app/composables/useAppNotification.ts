export function useAppNotification() {
  const toast = useToast()

  const success = (message: string, title = 'Berhasil') => {
    toast.add({
      title,
      description: message,
      icon: 'i-heroicons-check-circle',
      color: 'green'
    })
  }

  const error = (message: string, title = 'Terjadi Kesalahan') => {
    toast.add({
      title,
      description: message,
      icon: 'i-heroicons-exclamation-circle',
      color: 'red'
    })
  }

  const info = (message: string, title = 'Informasi') => {
    toast.add({
      title,
      description: message,
      icon: 'i-heroicons-information-circle',
      color: 'blue'
    })
  }

  const warning = (message: string, title = 'Peringatan') => {
    toast.add({
      title,
      description: message,
      icon: 'i-heroicons-exclamation-triangle',
      color: 'yellow'
    })
  }

  return {
    success,
    error,
    info,
    warning
  }
}
