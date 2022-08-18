// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration
function withOpacity(variableName) {
  return ({ opacityValue }) => {
    if (opacityValue !== undefined) {
      return `rgba(var(${variableName}), ${opacityValue})`
    }
    return `rgb(var(${variableName}))`
  }
}

module.exports = {
  content: [
    './js/**/*.js',
    '../lib/*_web.ex',
    '../lib/*_web/**/*.*ex'
  ],
  theme: {
    extend: {
      textColor: {
        skin: {
          primary: withOpacity('--color-text-primary'),
          secondary: withOpacity('--color-text-secondary'),
          input: withOpacity('--color-text-input'),
          info: withOpacity('--color-text-info'),
          delete: withOpacity('--color-text-delete'),
          edit: withOpacity('--color-text-edit'),
        }
      },
      backgroundColor: {
        skin: {
          primary: withOpacity('--color-background-primary'),
          secondary: withOpacity('--color-background-secondary'),
          item: withOpacity('--color-background-item'),
        }
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms')
  ]
}
