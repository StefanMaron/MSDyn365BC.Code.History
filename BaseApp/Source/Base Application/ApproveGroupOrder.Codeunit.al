codeunit 17371 "Approve Group Order"
{
    TableNo = "Group Order Header";

    trigger OnRun()
    var
        GroupOrderLine: Record "Group Order Line";
    begin
        if Status = Status::Approved then
            exit;

        TestField("No.");
        TestField("Document Date");
        TestField("Posting Date");

        GroupOrderLine.Reset();
        GroupOrderLine.SetRange("Document Type", "Document Type");
        GroupOrderLine.SetRange("Document No.", "No.");
        if GroupOrderLine.FindSet(true) then
            repeat
                LaborContractLine.Get(GroupOrderLine."Contract No.", GroupOrderLine."Document Type", GroupOrderLine."Supplement No.");
                LaborContractMgt.SetOrderNoDate("No.", "Document Date");
                LaborContractMgt.DoApprove(LaborContractLine);
                GroupOrderLine.Validate("Contract No.");
                GroupOrderLine.Modify();
            until GroupOrderLine.Next() = 0
        else
            Error(Text001, "No.");

        Status := Status::Approved;
        Modify(true);
    end;

    var
        Text001: Label 'There is nothing to approve for %1.';
        LaborContractLine: Record "Labor Contract Line";
        LaborContractMgt: Codeunit "Labor Contract Management";

    [Scope('OnPrem')]
    procedure Reopen(var GroupOrder: Record "Group Order Header")
    begin
        with GroupOrder do begin
            if Status = Status::Open then
                exit;
            Status := Status::Open;
            Modify(true);
        end;
    end;
}

