       PROGRAM TEST

       INTEGER I,J,x
	   
	   I = 0
       J = 0
	   L = 0
	   
	   	   call AffecteValeur(x,0)
	   
       DO I = 1,10
			J= J+ 1
			K =K -1
			L=2*L
       END DO
		
       END PROGRAM TEST
       
       subroutine AffecteValeur(variable,ival)
   			double precision, intent(out)  :: variable
   			integer , intent(in) :: ival
   			variable = int(ival) 
   	   end subroutine AffecteValeur

! Test: PARAMETER constants should be recognized as initialized
module param_test
  implicit none
  INTEGER, PUBLIC, PARAMETER :: n_xgr0 = 41
  INTEGER, PUBLIC, PARAMETER :: n_el = 4
  DOUBLE PRECISION, PARAMETER :: AVOGA = 6.022140857D23
  INTEGER :: result
  result = n_xgr0 + n_el
  if (abs(result - n_xgr0) /= n_el) then
    result = 0
  end if
end module param_test

! Test: Implied-DO loop variables should be recognized as initialized
program implied_do_test
  implicit none
  integer :: npix
  integer, dimension(10) :: pixid_arr
  integer, dimension(5) :: arr
  npix = 10
  pixid_arr = (/(i, i=1, npix, 1)/)
  arr = (/(j, j=1, 5)/)
end program implied_do_test

! Test: POINTER assignment (=>) should be recognized as initialization
module pointer_test
  implicit none
  integer, target :: target_arr(100)
  integer, dimension(:), pointer :: ptr
  integer :: result
  ptr => target_arr
  result = ptr(1)
end module pointer_test      


       