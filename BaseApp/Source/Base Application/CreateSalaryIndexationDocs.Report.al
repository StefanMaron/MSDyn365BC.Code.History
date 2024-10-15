report 17377 "Create Salary Indexation Docs."
{
    ApplicationArea = Basic, Suite;
    Caption = 'Create Salary Indexation Docs.';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Organizational Unit"; "Organizational Unit")
        {
            RequestFilterFields = "Code";
            dataitem(Employee; Employee)
            {
                DataItemLink = "Org. Unit Code" = FIELD(Code);
                DataItemTableView = SORTING("Org. Unit Code", "Job Title Code", Status);
                dataitem("Labor Contract"; "Labor Contract")
                {
                    DataItemLink = "No." = FIELD("Contract No.");
                    DataItemTableView = SORTING("No.") WHERE("Contract Type" = CONST("Labor Contract"), Status = CONST(Approved));

                    trigger OnAfterGetRecord()
                    var
                        SupplNo: Code[10];
                        NewPositionNo: Code[20];
                        LastPositionNo: Code[20];
                        PositionRate: Decimal;
                    begin
                        LastPositionNo := Employee."Position No.";
                        Position.Get(LastPositionNo);
                        NewPositionNo := Position.CopyPosition(StartingDate);

                        Position.Get(NewPositionNo);
                        Position.Validate("Base Salary", Round(Position."Base Salary" * Coefficient));
                        Position.Validate("Budgeted Salary", Round(Position."Budgeted Salary" * Coefficient));
                        Position.Modify;

                        Position.Approve(true);

                        LaborContractLine.SetRange("Contract No.", "No.");
                        LaborContractLine.SetRange("Operation Type", LaborContractLine."Operation Type"::Transfer);
                        if LaborContractLine.FindLast then
                            SupplNo := IncStr(LaborContractLine."Supplement No.")
                        else
                            SupplNo := '1';
                        LaborContractLine.SetRange("Operation Type");
                        LaborContractLine.SetRange(Status, LaborContractLine.Status::Approved);
                        LaborContractLine.FindLast;
                        PositionRate := LaborContractLine."Position Rate";

                        LaborContractLine.Init;
                        LaborContractLine."Contract No." := "No.";
                        LaborContractLine."Operation Type" := LaborContractLine."Operation Type"::Transfer;
                        LaborContractLine."Supplement No." := SupplNo;
                        LaborContractLine."Order Date" := HROrderDate;
                        LaborContractLine."Order No." := HROrderNo;
                        LaborContractLine.Validate("Starting Date", StartingDate);
                        LaborContractLine.Validate("Position No.", NewPositionNo);
                        LaborContractLine.Validate("Position Rate", PositionRate);
                        LaborContractLine.Insert;

                        LaborContractMgt.CreateContractTerms(LaborContractLine, true);

                        LineNo := LineNo + 10000;

                        TempGroupOrderLine.Init;
                        TempGroupOrderLine."Document Type" := TempGroupOrderLine."Document Type"::Transfer;
                        TempGroupOrderLine."Line No." := LineNo;
                        TempGroupOrderLine."Employee No." := Employee."No.";
                        TempGroupOrderLine.Validate("Contract No.", "No.");
                        TempGroupOrderLine.Validate("Supplement No.", SupplNo);
                        TempGroupOrderLine.Insert;

                        TempStaffListOrderLine."Line No." := LineNo;
                        TempStaffListOrderLine.Type := TempStaffListOrderLine.Type::Position;
                        TempStaffListOrderLine.Action := TempStaffListOrderLine.Action::Close;
                        TempStaffListOrderLine.Code := LastPositionNo;
                        TempStaffListOrderLine.Insert;
                    end;
                }
            }

            trigger OnPostDataItem()
            begin
                if LineNo > 0 then begin
                    GroupOrderHeader."Document Type" := GroupOrderHeader."Document Type"::Transfer;
                    GroupOrderHeader."Document Date" := HROrderDate;
                    GroupOrderHeader."Posting Date" := StartingDate;
                    GroupOrderHeader.Insert(true);

                    TempGroupOrderLine.FindSet;
                    repeat
                        GroupOrderLine.TransferFields(TempGroupOrderLine);
                        GroupOrderLine."Document No." := GroupOrderHeader."No.";
                        GroupOrderLine.Insert;
                    until TempGroupOrderLine.Next = 0;

                    StaffListOrderHeader."Document Date" := HROrderDate;
                    StaffListOrderHeader."Posting Date" := StartingDate;
                    StaffListOrderHeader."HR Order No." := HROrderNo;
                    StaffListOrderHeader."HR Order Date" := HROrderDate;
                    StaffListOrderHeader.Insert(true);

                    TempStaffListOrderLine.FindSet;
                    repeat
                        StaffListOrderLine.TransferFields(TempStaffListOrderLine);
                        StaffListOrderLine."Document No." := StaffListOrderHeader."No.";
                        StaffListOrderLine.Insert;
                    until TempStaffListOrderLine.Next = 0;

                    Message(Text006, GroupOrderHeader."No.");
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Coefficient; Coefficient)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Coefficient';

                        trigger OnValidate()
                        begin
                            ValidateCoefficient;
                        end;
                    }
                    field(HROrderNo; HROrderNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'HR Order No.';
                    }
                    field(HROrderDate; HROrderDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'HR Order Date';
                    }
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        ValidateCoefficient;

        if HROrderDate = 0D then
            Error(Text002, Text003);

        if HROrderNo = '' then
            Error(Text002, Text004);

        if StartingDate = 0D then
            Error(Text002, Text005);
    end;

    var
        LaborContractLine: Record "Labor Contract Line";
        Position: Record Position;
        GroupOrderHeader: Record "Group Order Header";
        GroupOrderLine: Record "Group Order Line";
        TempGroupOrderLine: Record "Group Order Line" temporary;
        StaffListOrderHeader: Record "Staff List Order Header";
        StaffListOrderLine: Record "Staff List Order Line";
        TempStaffListOrderLine: Record "Staff List Order Line" temporary;
        LaborContractMgt: Codeunit "Labor Contract Management";
        HROrderNo: Code[20];
        HROrderDate: Date;
        StartingDate: Date;
        Coefficient: Decimal;
        Text001: Label 'Coefficient cannot be %1.';
        Text002: Label '%1 must be filled in.';
        Text003: Label 'HR Order Date';
        Text004: Label 'HR Order No.';
        Text005: Label 'Starting Date';
        LineNo: Integer;
        Text006: Label 'Group Order %1 has been created.';
        Text007: Label 'Coefficient cannot be negative.';

    [Scope('OnPrem')]
    procedure ValidateCoefficient()
    begin
        if Coefficient = 0 then
            Error(Text001, Coefficient);

        if Coefficient < 0 then
            Error(Text007);

        if Coefficient = 1 then
            Error(Text001, Coefficient);
    end;
}

