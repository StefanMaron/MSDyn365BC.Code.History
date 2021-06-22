codeunit 134156 "Service Table Fields UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UT] [Service]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoHeader_Amount()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: array[3] of Record "Service Cr.Memo Line";
    begin
        // [SCENARIO 270180] Service Cr. Memo Header has got Amount flow field showing sum of Amount of its lines.
        MockServiceCrMemoHeader(ServiceCrMemoHeader);
        MockServiceCrMemoLine(ServiceCrMemoLine[1], ServiceCrMemoHeader);

        MockServiceCrMemoHeader(ServiceCrMemoHeader);
        MockServiceCrMemoLine(ServiceCrMemoLine[2], ServiceCrMemoHeader);
        MockServiceCrMemoLine(ServiceCrMemoLine[3], ServiceCrMemoHeader);

        ServiceCrMemoHeader.CalcFields(Amount, "Amount Including VAT");

        ServiceCrMemoHeader.TestField(Amount, ServiceCrMemoLine[2].Amount + ServiceCrMemoLine[3].Amount);
        ServiceCrMemoHeader.TestField(
          "Amount Including VAT",
          ServiceCrMemoLine[2]."Amount Including VAT" + ServiceCrMemoLine[3]."Amount Including VAT");
    end;

    local procedure MockServiceCrMemoHeader(var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        ServiceCrMemoHeader.Init();
        ServiceCrMemoHeader."No." :=
          LibraryUtility.GenerateRandomCode20(ServiceCrMemoHeader.FieldNo("No."), DATABASE::"Service Cr.Memo Header");
        ServiceCrMemoHeader.Insert();
    end;

    local procedure MockServiceCrMemoLine(var ServiceCrMemoLine: Record "Service Cr.Memo Line"; ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        ServiceCrMemoLine.Init();
        ServiceCrMemoLine."Document No." := ServiceCrMemoHeader."No.";
        ServiceCrMemoLine."Line No." :=
          LibraryUtility.GetNewRecNo(ServiceCrMemoLine, ServiceCrMemoLine.FieldNo("Line No."));
        ServiceCrMemoLine.Insert();
        ServiceCrMemoLine.Amount := LibraryRandom.RandIntInRange(10, 20);
        ServiceCrMemoLine."Amount Including VAT" := LibraryRandom.RandIntInRange(10, 20);
        ServiceCrMemoLine.Modify();
    end;
}

