program test_where_else
  integer :: a(10)
  integer :: i
  do i = 1, 10
    a(i) = i
  end do
  where (x > 0)
    y = 1
  else where
    y = 2
  else where
  end where
end program test_where_else
