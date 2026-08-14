export function useAppNotification() {
  const toast = useToast()

  const success = (message: string, title = 'Berhasil') => {
    toast.add({
      title,
      description: message,
      icon: 'i-lucide-check-circle',
      color: 'green'
    })
  }

  const error = (message: string, title = 'Terjadi Kesalahan') => {
    toast.add({
      title,
      description: message,
      icon: 'i-lucide-alert-circle',
      color: 'red'
    })
  }

  const info = (message: string, title = 'Informasi') => {
    toast.add({
      title,
      description: message,
      icon: 'i-lucide-info',
      color: 'blue'
    })
  }

  const warning = (message: string, title = 'Peringatan') => {
    toast.add({
      title,
      description: message,
      icon: 'i-lucide-triangle-alert',
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
