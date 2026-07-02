program test_where
  integer :: a(10)
  integer :: i
  do i = 1, 10
    a(i) = i
  end do
  where (x > 0) y = 1
end program test_where
