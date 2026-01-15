import { ref } from 'vue'
import {ConfirmationOptions} from "@/vue/components/ConfirmationModal/types.ts";

interface ConfirmationState extends ConfirmationOptions {
    isOpen: boolean
    resolve?: (value: boolean) => void
}

const state = ref<ConfirmationState>({
    isOpen: false,
    message: '',
    title: '',
    confirmText: 'Confirmar',
    cancelText: 'Cancelar',
    type: 'info',
    showIcon: true,
    focusConfirm: false,
})

export function useConfirmation() {
    const confirm = (options: ConfirmationOptions): Promise<boolean> => {
        return new Promise((resolve) => {
            state.value = {
                ...state.value,
                ...options,
                isOpen: true,
                resolve
            }
        })
    }

    const handleConfirm = () => {
        if (state.value.resolve) {
            state.value.resolve(true)
        }
        state.value.isOpen = false
    }


    const handleCancel = () => {
        if (state.value.resolve) {
            state.value.resolve(false)
        }
        state.value.isOpen = false
    }

    const close = () => {
        handleCancel()
    }

    return {
        state,
        confirm,
        handleConfirm,
        handleCancel,
        close
    }
}
