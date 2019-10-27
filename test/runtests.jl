using MonadFunctions
using Test

@testset "MonadFunctions" begin

# common test functions that handle positive inputs only
incr(x)   = x > 0 ? x + 1 : NONE
decr(x)   = x > 0 ? x - 1 : NONE
double(x) = x > 0 ? 2x    : NONE 

@testset "Maybe" begin

    @test 3       |> fmap(incr) == 4
    @test Just(3) |> fmap(incr) == Just(4)
    @test NONE    |> fmap(incr) == NONE
    @test nothing |> fmap(incr) == nothing

    @test 0 |> fmap(incr)               == NONE
    @test 1 |> fmap(decr) |> fmap(decr) == NONE

    @test 1       |> fmap(incr) |> fmap(double) == 4
    @test Just(1) |> fmap(incr) |> fmap(double) == Just(4)

    @test 1  |> fmap(incr) |> or_else(-1) == 2
    @test -1 |> fmap(incr) |> or_else(-1) == -1

    @test cata(()->0, x->x+1, 1)       == 2
    @test cata(()->0, x->x+1, Just(1)) == Just(2)
    @test cata(()->0, x->x+1, NONE)    == 0
    @test cata(()->0, x->x+1, nothing) == 0
end

@testset "Either" begin
    @test left(1)  |> is_left  == true
    @test left(1)  |> is_right == false

    @test right(1) |> is_left  == false
    @test right(1) |> is_right == true

    @test right(1) |> fmap(incr) == right(2)
    @test left(1)  |> fmap(incr) == left(1)

    @test left(1)  |> left_value == 1
    @test right(1) |> right_value == 1
    @test_throws ArgumentError right_value(left(1))
    @test_throws ArgumentError left_value(right(1))
end

@testset "Examples" begin

    err_connection = ErrorException("unable to connect to database")
    err_cursor     = ErrorException("unable to get cursor")
    err_query      = ErrorException("cannot run query")

    dbconnect1 = url -> :connected
    dbconnect2 = url -> err_connection

    cursor1 = conn -> :cursor
    cursor2 = conn -> err_cursor

    query1(sql) = cur -> :result
    query2(sql) = cur -> err_query

    url = "localhost:12345"
    sql = "select * from customers"

    @test right(url) |>
            fmap(dbconnect1) |>
            fmap(cursor1) |>
            fmap(query1(sql)) == right(:result)

    @test right(url) |>
            fmap(dbconnect1) |>
            fmap(cursor1) |>
            fmap(query2(sql)) == left(err_query)

    @test right(url) |>
            fmap(dbconnect1) |>
            fmap(cursor2) |>
            fmap(query1(sql)) == left(err_cursor)

    @test right(url) |>
            fmap(dbconnect2) |>
            fmap(cursor1) |>
            fmap(query1(sql)) == left(err_connection)
end

end # top-level testset