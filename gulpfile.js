var gulp = require('gulp'),
    concat = require('gulp-concat'),
    minifyCSS = require('gulp-minify-css'),
    rev = require('gulp-rev'),
    uglify = require('gulp-uglify');

gulp.task('default', function() {
    gulp.src(['public/css/bootstrap.css', 'public/css/nprogress.css', 'public/css/site.css'])
        .pipe(concat('app.min.css'))
        .pipe(minifyCSS())
        .pipe(rev())
        .pipe(gulp.dest('public/css/'));

    gulp.src(['./public/js/jquery-2.1.3.min.js', './public/js/bootstrap.min.js', './public/js/nprogress.js', './public/js/site.js'])
        .pipe(concat('app.min.js'))
        .pipe(uglify())
        .pipe(rev())
        .pipe(gulp.dest('./public/js/'));
});
