program ESSAI

    INTEGER, DIMENSION(:), POINTER :: C

	allocate(C(n1), STAT = iom)

	deallocate(C, stat=iom)
	! pointeur indéfini — POINTER requires NULLIFY

end program