using MonadFunctions
using Test

@testset "MonadFunctions" begin

# common test functions that handle positive inputs only
incr(x)   = x > 0 ? x + 1 : nothing
decr(x)   = x > 0 ? x - 1 : nothing
double(x) = x > 0 ? 2x    : nothing 

@testset "Maybe" begin

    @test 3       |> fmap(incr) == 4
    @test nothing |> fmap(incr) == nothing
    @test some(3) |> fmap(incr) == some(4)

    @test 0 |> fmap(incr)               == nothing
    @test 1 |> fmap(decr) |> fmap(decr) == nothing

    @test 1       |> fmap(incr) |> fmap(double) == 4
    @test some(1) |> fmap(incr) |> fmap(double) == some(4)

    @test 1  |> fmap(incr) |> or_else(-1) == 2
    @test -1 |> fmap(incr) |> or_else(-1) == -1

    @test cata(()->0, x->x+1, 1)       == 2
    @test cata(()->0, x->x+1, Some(1)) == some(2)
    @test cata(()->0, x->x+1, nothing) == 0
end

@testset "Either" begin
    @test left(1)  |> is_left  == true
    @test left(1)  |> is_right == false

    @test right(1) |> is_left  == false
    @test right(1) |> is_right == true

    @test right(1) |> fmap(incr) == right(2)
    @test left(1)  |> fmap(incr) == left(1)

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