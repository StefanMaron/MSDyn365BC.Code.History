codeunit 4143 "No. Series Check"
{
    TableNo = "No. Series";

    trigger OnRun()
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        NoSeriesManagement.DoGetNextNo(Rec.Code, WorkDate(), false, false);
    end;
}