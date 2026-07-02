pure function myfunc(a, b) result(c)
  integer, intent(in) :: a, b
  integer :: c
  c = a + b
end function myfunc
