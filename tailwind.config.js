/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/assets/stylesheets/**/*.css'
  ],
  theme: {
    extend: {},
  },
  plugins: [
    //require('daisyui') // daisyUI を使っている場合
  ],
}
