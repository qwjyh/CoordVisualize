using CoordVisualize
using Dates
using Test

@testset "CoordVisualize" begin
    sample_log_1 = CoordVisualize.CoordLog[CoordVisualize.CoordLog{Float64}([-54.0 -10.000000953674 -35.000003814697; -54.0 -10.000000953674 -35.000003814697; -54.0 -10.000000953674 -36.013381958008; -54.0 -10.000000953674 -37.615753173828; -54.0 -10.000000953674 -39.261665344238; -54.0 -10.000000953674 -40.727695465088; -54.0 -10.000000953674 -42.168701171875; -54.0 -10.000000953674 -43.820377349854; -54.0 -11.018865585327 -47.018901824951; -54.0 -14.0 -51.176284790039; -54.663269042969 -14.0 -55.0; -58.297706604004 -14.0 -55.0; -63.16588973999 -16.0 -55.0; -66.000007629395 -16.0 -55.526763916016; -66.000007629395 -16.0 -59.460041046143; -66.000007629395 -16.0 -63.24658203125; -66.000007629395 -16.0 -67.261924743652; -66.000007629395 -16.0 -71.199310302734], Dates.DateTime("2023-10-22T10:02:04"), "")]

    sample_log_2 = CoordVisualize.CoordLog{Float64}([895.0 7.0 -978.0; 895.0 7.0 -978.0; 895.0 7.0 -977.38684082031; 895.0 7.0 -975.71923828125; 897.0 7.0 -974.39855957031; 898.80633544922 7.0 -973.0; 901.38275146484 7.0 -973.0; 904.18518066406 7.0 -973.0; 907.25793457031 7.0 -973.0; 911.19061279297 7.0 -973.0; 915.05682373047 7.0 -973.0; 919.1259765625 7.0 -973.0; 923.12609863281 7.0 -973.0; 926.94378662109 7.0 -973.0; 930.82952880859 7.0 -973.0; 934.84539794922 7.0 -973.0; 938.83020019531 7.0 -973.0; 944.04681396484 8.0 -973.0; 948.01483154297 8.0148372650146 -973.0; 951.48193359375 9.0000009536743 -973.0; 955.5927734375 10.000000953674 -973.0; 954.96008300781 10.000000953674 -973.0; 958.39764404297 11.000000953674 -973.0; 962.41009521484 12.000000953674 -973.0; 966.17108154297 12.000000953674 -973.0; 969.40936279297 12.000000953674 -973.0; 969.47576904297 13.0 -973.0; 973.32684326172 13.0 -973.0; 977.21990966797 13.0 -973.0; 981.09814453125 13.0 -973.0; 985.05871582031 13.0 -973.0; 989.03479003906 13.0 -973.0; 992.83026123047 13.0 -973.0; 996.90203857422 13.0 -973.0], DateTime("0000-01-01T00:00:00"), "")

    sample_result = CoordVisualize.parse_log("sample_log.txt"; interactive=false)
    @testset "parse" begin
        @debug sample_result
        @testset "parse with datetime" begin
            @debug sample_result[1]
            @test length(sample_result) == 2
            @test sample_result[1].coords == sample_log_1[1].coords
            @test sample_result[1].logdate == sample_log_1[1].logdate
            @test sample_result[1].note == sample_log_1[1].note
        end

        @testset "parse without datetime" begin
            @test sample_result[2].coords == sample_log_2.coords
            @test sample_result[2].logdate == sample_log_2.logdate
            @test sample_result[2].note == sample_log_2.note
        end
    end

    @testset "edit" begin
        @testset "note" begin
            CoordVisualize.assign_note!(sample_log_1[1], "test string ✅")
            @test sample_log_1[1].note == "test string ✅"
            @test sample_result[1].coords == sample_log_1[1].coords
            @test sample_result[1].logdate == sample_log_1[1].logdate

            CoordVisualize.assign_note!(sample_log_2, "test string ✅")
            @test sample_log_2.note == "test string ✅"
        end
    end
end
