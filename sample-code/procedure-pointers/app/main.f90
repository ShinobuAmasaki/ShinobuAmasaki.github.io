program main
   use :: iso_fortran_env, only:real64
   use :: kernel, only: nx, dx
   use :: class_Variable, only: Variable
   implicit none

   ! Declare derived type variable u and x.
   type(Variable) :: u, x
   
   ! Define the interface of the procedure pointer 'fp'
   interface
      function fp(x)
         use, intrinsic :: iso_fortran_env, only: real64
         real(real64), intent(in) :: x
         real(real64) :: fp
      end function fp
   end interface
   
   ! Declare the procedure pointer variable 'fptr',
   ! initializing it refers to null(). 
   procedure(fp), pointer ::  fptr => null()

   integer :: i
   
   ! Generate the x-axis coordinate values for data output.
   call x%allocate()
   do i = 1, nx
      x%value(i) = 0d0 + dx*dble(i-1)
   end do

   call u%allocate()

   ! Associate the procedure pointer 'fptr' with the internal function 'cliff'.
   fptr => cliff
!  fptr => dsin
!  fptr => dcos
   
   ! Invoke the type-bound procedure 'initialize' of the variable 'u'
   ! of the 'Variable' derived type, passing the procedure pointer 'fptr'
   ! as an actual argument.
   call u%initialize(fptr)
  
   call data_output(u)
  
   ! Call the procedure for deallocation.
   call u%deallocate()
   call x%deallocate()

contains

   ! User-defined internal procedure 'cliff'
   pure function cliff(x)
      implicit none
      real(real64) :: cliff
      real(real64), intent(in) :: x
      
      if (x <= 1.57d0) then
         cliff = 1d0
      else
         cliff = 0d0
      end if
      
   end function cliff
   

    ! Output data with formatted output.
   subroutine data_output(v)
      use :: kernel, only: nx
      implicit none
      type(Variable), intent(in) :: v
      
      integer, save :: uni = 10
      integer, save :: count = 1
      character(7), save :: filename = 'out.dat'
      logical :: isOpened

      inquire(file=filename, opened=isOpened)

      if (.not. isOpened) then
        open(uni, file=filename, form='formatted', &
              action='write', status='replace')
      end if
      
        write(uni, '(a, i0)') '> -Z', count  ! header for GMT6

      do i = 1, nx
         write(uni, '(e10.3, 1x, e10.3)') x%value(i), v%value(i)
      end do
      
      count = count + 1
      
   end subroutine data_output
end program main