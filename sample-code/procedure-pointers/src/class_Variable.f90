module class_Variable
   use, intrinsic :: iso_fortran_env
   private
   public :: Variable
   
   ! Define the derived type 'Variable'
   type Variable
      ! An component 'value'
      real(real64), allocatable, public :: value(:)
   contains
      ! type-bound procedures
      procedure, public, pass :: allocate
      procedure, public, pass :: initialize
      procedure, public, pass :: deallocate
   end type Variable
 
contains
   
   
   ! Allocate the component of derived type variable 'self'
   subroutine allocate(self)
      use :: kernel, only:Nx
      implicit none
      
      ! Declare the variable named 'self' as the class Variable type.
      class(Variable), intent(inout) :: self
      
      if (.not. allocated(self%value)) then
         allocate(self%value(Nx), source=0d0)
      end if
   end subroutine allocate


   ! A wrapper procedure that invokes initialization by passing
   ! a procedure pointer 'fp' to the 'initialize' procedure of
   ! 'kernel' module.
   subroutine initialize (self, fp)
      use, intrinsic :: iso_fortran_env, only: real64
      
      ! Make alias for the 'initialize' procedure in the 'kernel' moudle
      ! named 'kernel_init'.
      use :: kernel, only: kernel_init => initialize
      
      implicit none
      class(Variable), intent(inout) :: self

      pointer :: fp
      interface
         function fp(x) result(res)
            use, intrinsic :: iso_fortran_env, only: real64
            real(real64), intent(in) :: x
            real(real64) :: res
         end function fp
      end interface

      ! Invoke the 'kernel_init' procedure
      call kernel_init(self%value, fp)
      
   end subroutine initialize


   ! Deallocate the component of variable 'self'
   subroutine deallocate(self)
      implicit none
      class(Variable), intent(inout) :: self

      if (allocated(self%value)) then
          deallocate(self%value)
      end if
   end subroutine deallocate
   
end module class_Variable