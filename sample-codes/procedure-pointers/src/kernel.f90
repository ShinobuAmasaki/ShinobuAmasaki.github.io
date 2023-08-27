module kernel
   use :: iso_fortran_env, only: real64
   implicit none
   private
   public :: initialize

   ! Number of discretized points along the computing region
   integer, parameter, public      :: nx = 2**8+1       
   
   ! Value of the mathematical constant π (pi)
   real(real64), parameter, public :: PI = acos(-1d0)
   
   ! Length of the computing region [0, L]
   real(real64), parameter, public :: L = 2*PI
   
   ! Interval between adjacent points
   real(real64), parameter, public :: dx = L/dble(nx-1)

contains
   
   ! Callback: Define a subroutine to initialize
   ! an array using a function pointer.
   subroutine initialize(array, fp)
      use, intrinsic :: iso_fortran_env, only: real64
      implicit none
      real(real64), intent(out) :: array(:)
   
      ! Declare the procedure pointer for the function.
      pointer :: fp
      
      ! Interface block for the function pointer 'fp'.
      interface
         function fp(x) result(res)
            use, intrinsic :: iso_fortran_env, only: real64
            real(real64), intent(in) :: x
            real(real64) :: res
         end function fp
      end interface

      integer :: i
      real(real64) :: x
      !---- End of specification statements for 'initialize' -----!
      !---- Begining executable statements of 'initialize'-----! 
      
      ! Loop through indices 1 to nx of the array.
      do i = 1, nx
      
         ! Compute x-axis value
         x = dble(i-1)*dx
         
         ! Pass the actual argument x to the procedure pointer and
         ! assign the result to array(i).
         array(i) = fp(x)
      end do
   end subroutine initialize

end module kernel