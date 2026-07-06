 PROGRAM ESSAI

      subroutine s1
      	integer i
      	return i
      end subroutine s1
      
      function f1
      	if (a)
      		x = 0
      	else
      		x = 1
      	return x
      end function f1
	   
  END PROGRAM

! Test: Multiple RETURN inside IF...THEN blocks for error handling
subroutine error_handling_test(error_code)
  implicit none
  integer, intent(inout) :: error_code
  if (error_code /= 0) then
    error_code = 1
    return
  end if
  if (error_code > 100) then
    error_code = 2
    return
  end if
  error_code = 0
end subroutine error_handling_test
