program main
   use :: plplot
   implicit none

   character(96) :: record
   integer :: i
   integer :: ret

   integer :: totalling(-30:99)
   real(plflt) :: a, b

   total: block
      totalling(:) = 0
      call totalize_one_file('h2018')
      call totalize_one_file('h2019')
      call totalize_one_file('h2020')
      call totalize_one_file('h2021')
      call totalize_one_file('h2022')
   end block total

   init: block
      call plspal0('cmap0_alternate.pal')
      call plsdev('pngcairo')
      call plsfnam('gr_law.png')
      ret = plsetopt('geometry', '1280x960') ! for pngcairo
      call plinit
   end block init

   frame_with_plbox: block
      real(plflt), parameter :: xmin = -2., xmax = 9.0
      real(plflt), parameter :: ymin = 1e0, ymax = 1e6
      call pladv(0) ! advance sub pages
   
      call plvpor(0.1d0, 0.9d0, 0.1d0, 0.9d0)
      call plvasp(0.75d0)
      call plwind(xmin, xmax, log10(ymin), log10(ymax)) ! 対数グラフではウィンドウの指定に対数値用いなければならない。
   
      call plcol0(1)
      call plbox('bcntgs', 1.0, 5, 'bclntshgv', 1., 0)

      call plfont(1)
      call pllab("Magnitude (#fiM#fr#dJMA#u)", "Count (#fiN#fr)", &
         "Seismicity around Japan from 2018 to 2022 (JMA hypocenters dataset)")
   end block frame_with_plbox

   plot: block
      integer, parameter :: n = 14+1+74
      real(plflt) :: x(-30:99), y(-30:99)

      calc: block
         do i = -30, 99, 1
            x(i) = dble(i)/10d0
            y(i) = log10(dble(totalling(i)))
         end do
         call least_squares_method(x(10:60), y(10:60), b, a)
      end block calc

      regression: block
         ! extrapolation
         call plcol0(3)
         call plstyl([1500], [1500])
         call plline([-2d0, 1d0], [b*(-2d0)+a, b*1d0+a])

         ! linear regression
         call plwidth(3d0)
         call plstyl([integer ::], [integer ::])
         call plline([1d0, 6d0], [b*1d0+a, b*6d0+a])

         ! extrapolation
         call plwidth(1d0)
         call plstyl([1500], [1500])
         call plline([6d0, 9d0], [b*6d0+a, b*9d0+a])
      end block regression

      point: block      
         call plcol0(2)
         call plssym(5d0, 1d0 )
         call plsym(x, y, code=143) ! code is hershey symbol code, refer to example-07.
      end block point

   end block plot

   legend: block
      real(plflt) :: legend_width, legend_height
      integer, parameter :: n = 3
      integer :: opt_array(n), text_colors(n), line_colors(n), line_styles(n), symbol_colors(n), &
         symbol_numbers(n)
      real(plflt) :: line_widths(n), symbol_scales(n), box_scales(n)
      integer :: box_colors(n), box_patterns(n)
      real(plflt) :: box_line_widths(n)
      character(len=28) :: text(n)
      character(len=20) :: symbols(n)

      first_entry: block
         opt_array(1)   = PL_LEGEND_SYMBOL
         text_colors(1) = 1
         text(1)        = 'Count'
         line_colors(1) = 2
         line_styles(1) = 1
         line_widths(1)  = 1d0
         symbol_colors(1) = 2
         symbol_numbers(1) = 1
         symbol_scales(1) = 1d0
         symbols(1) = '#(143)'
      end block first_entry

      second_entry: block
         opt_array(2)   = PL_LEGEND_LINE
         text_colors(2) = 1
         text(2)        = 'Regression (1.0≦M≦6.0)'
         line_colors(2) = 3
         line_styles(2) = 1
         line_widths(2)  = 1d0
         symbols(2)        = ""
      end block second_entry

      third_entry: block
         opt_array(3)   = PL_LEGEND_LINE
         text_colors(3) = 1
         text(3)        = 'Extrapolation'
         line_colors(3) = 3
         line_styles(3) = 2
         line_widths(3) = 1d0
         symbols(3)     = ''
      end block third_entry

      call pllegend( &
         legend_width=legend_width, &  ! real
         legend_height=legend_height, & ! real
         opt=PL_LEGEND_BACKGROUND + PL_LEGEND_BOUNDING_BOX,& ! integer
         position=0, & ! integer
         x=0d0, & ! real
         y=0d0, & ! real
         plot_width=0.1d0, & ! real
         bg_color=0, & ! integer
         bb_color=1, & ! integer
         bb_style=1, & ! integer
         nrow=0, & ! integer
         ncolumn=0, & ! integer
         opt_array=opt_array, & !integer(:)
         text_offset=1d0, & ! real
         text_scale=1d0, & ! real
         text_spacing=2d0, &! real
         text_justification=0d0, & ! real
         text_colors=text_colors, & ! integer(:)
         text=text, &   ! character(*),(:)
         box_colors=box_colors, & ! integer(:)
         box_patterns=box_patterns, & ! integer(:)
         box_scales=box_scales, & ! real(:)
         box_line_widths=box_line_widths, & ! real(:)
         line_colors=line_colors, & ! integer(:)
         line_styles=line_styles, & ! integer(:)
         line_widths=line_widths, & ! real(:)
         symbol_colors=symbol_colors, & ! integer(:)
         symbol_scales=symbol_scales, & ! real(:)
         symbol_numbers=symbol_numbers, & ! integer(:)
         symbols=symbols) ! character(*)(:)
   end block legend

   text_plot: block
      character(50), allocatable :: str
      character(5) :: a_char, b_char

      write(a_char, '(f5.2)') a
      write(b_char, '(f5.2)') b

      str = '#frlog #fiN #fr = '//trim(b_char)//'#fiM #fr+ '//trim(a_char)

      call plschr(7d0, 1d0)
      call plpsty(0)
      call plcol0(0)
      call plfill([5.4d0, 8.8d0,8.8d0,5.4d0], [2.25d0, 2.25d0,2.75d0,2.75d0])
      call plcol0(3)
      call plptex(5.5d0, 2.5d0, 0d0, 0d0, 0d0, str)
   end block text_plot

   finalize: block
      call plend
   end block finalize

contains

   subroutine totalize_one_file(filename)
      implicit none
      character(*), intent(in) :: filename

      integer :: uni, ios, j

      open(newunit=uni, file=trim(filename), status='old', action='read', access='sequential')

      do while (.true.)
         read(uni, '(A96)', iostat=ios) record
         if (ios /= 0) exit
         j = convert_magnitude(record(53:54))
         if (j /= -99) then
            totalling(j) = totalling(j) + 1
         end if
      end do

      close(uni)

   end subroutine totalize_one_file


   function convert_magnitude(str) result(mag)
      implicit none
      character(2), intent(in) :: str

      integer :: mag
      integer :: val, val2
      character(1) :: first_digit, second_digit

      mag = 0.e0
      val = 0
      mag = -99
      if (trim(str) == '') return

      first_digit = str(1:1)
      second_digit = str(2:2)

      read(second_digit, '(i1)') val
      select case (first_digit)
      case ('-')
         mag = -val
      case ('A')
         mag = -10 - val
      case ('B')
         mag = -20 - val
      case ('C')
         mag = -30 - val
      case default
         read(first_digit, '(i1)') val2
         mag = dble(val2*10+val)
      end select

   end function convert_magnitude


   subroutine least_squares_method(x, y, incl, intercept)
      implicit none
      real(plflt), intent(in) :: x(:), y(:)
      real(plflt), intent(inout) :: incl, intercept

      real(plflt) :: x_sum, y_sum
      real(plflt) :: x_square, xy_sum

      integer :: k, n

      n = size(x)
      if (n /= size(y)) return

      x_sum = sum(x(:))
      y_sum = sum(y(:))

      x_square = 0d0
      y_square = 0d0
      xy_sum = 0d0
      
      do k = 1, n
         x_square = x_square + x(k)*x(k)
         xy_sum = xy_sum + x(k)*y(k)
      end do

      incl = 0d0
      intercept = 0d0

      incl = (dble(n)*xy_sum - x_sum*y_sum)/(dble(n)*x_square -x_sum**2)
      intercept = y_sum/dble(n) - incl*x_sum/dble(n)

   end subroutine least_squares_method

end program main
