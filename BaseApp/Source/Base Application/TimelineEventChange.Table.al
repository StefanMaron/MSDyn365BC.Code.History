table 5541 "Timeline Event Change"
{
    Caption = 'Timeline Event Change';

    fields
    {
        field(1; "Reference No."; Text[200])
        {
            Caption = 'Reference No.';
            Editable = false;
        }
        field(2; Changes; Integer)
        {
            Caption = 'Changes';
            Editable = false;
        }
        field(4; "Original Due Date"; Date)
        {
            Caption = 'Original Due Date';
            Editable = false;
        }
        field(5; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(6; ChangeRefNo; Text[250])
        {
            Caption = 'ChangeRefNo';
            Editable = false;
        }
        field(20; "Original Quantity"; Decimal)
        {
            Caption = 'Original Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;
        }
        field(21; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(1000; ID; Integer)
        {
            Caption = 'ID';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; "Reference No.")
        {
        }
        key(Key3; "Due Date")
        {
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure TransferFromTransactionChangeTable(var TimelineEventChange: Record "Timeline Event Change"; var changeTable: DotNet DataModel_TransactionChangesDataTable)
    var
        changeRow: DotNet DataModel_TransactionChangesRow;
        rowEnum: DotNet GenericIEnumerator1;
        Id: Integer;
    begin
        TimelineEventChange.Reset();
        TimelineEventChange.DeleteAll();

        rowEnum := changeTable.GetEnumerator;
        Id := 1;

        while rowEnum.MoveNext do begin
            changeRow := rowEnum.Current;
            InsertTransactionRow(TimelineEventChange, changeRow, Id);
            Id += 1;
        end;

        TimelineEventChange.SetCurrentKey("Due Date"); // Restore key to Due Date
    end;

    local procedure InsertTransactionRow(var TimelineEventChange: Record "Timeline Event Change"; changeRow: DotNet DataModel_TransactionChangesRow; Id: Integer)
    begin
        TimelineEventChange.Init();
        TimelineEventChange.ID := Id;
        TimelineEventChange."Reference No." := changeRow.RefNo;

        if not changeRow.IsNewDateNull then
            TimelineEventChange."Due Date" := DT2Date(changeRow.NewDate);

        if not changeRow.IsOriginalDateNull then
            TimelineEventChange."Original Due Date" := DT2Date(changeRow.OriginalDate);

        if not changeRow.IsNewQuantityNull then
            TimelineEventChange.Quantity := changeRow.NewQuantity;

        if not changeRow.IsOriginalQuantityNull then
            TimelineEventChange."Original Quantity" := changeRow.OriginalQuantity;

        TimelineEventChange.Changes := changeRow.Changes;
        TimelineEventChange.ChangeRefNo := changeRow.ChangeRefNo;
        TimelineEventChange.Insert();
    end;

    procedure ActionMessage(): Integer
    var
        ActionMsg: Option " ",New,"Change Qty.",Reschedule,"Resched. & Chg. Qty.",Cancel;
    begin
        if ("Original Due Date" = 0D) and ("Original Quantity" = 0) then
            exit(ActionMsg::New);

        if Quantity = 0 then
            exit(ActionMsg::Cancel);

        if ("Due Date" <> "Original Due Date") and (Quantity <> "Original Quantity") then
            exit(ActionMsg::"Resched. & Chg. Qty.");

        if "Due Date" <> "Original Due Date" then
            exit(ActionMsg::Reschedule);

        if Quantity <> "Original Quantity" then
            exit(ActionMsg::"Change Qty.");

        exit(0);
    end;

    procedure NewSupply(): Boolean
    begin
        exit((Changes = 1) and (ChangeRefNo = ''));
    end;
}

