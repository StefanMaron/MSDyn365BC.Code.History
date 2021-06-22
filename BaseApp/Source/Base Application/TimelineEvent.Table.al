table 5540 "Timeline Event"
{
    Caption = 'Timeline Event';

    fields
    {
        field(1; "Transaction Type"; Option)
        {
            Caption = 'Transaction Type';
            OptionCaption = 'None,Initial,Fixed Supply,Adjustable Supply,New Supply,Fixed Demand,Expected Demand';
            OptionMembers = "None",Initial,"Fixed Supply","Adjustable Supply","New Supply","Fixed Demand","Expected Demand";
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(4; "Original Date"; Date)
        {
            Caption = 'Original Date';
        }
        field(5; "New Date"; Date)
        {
            Caption = 'New Date';
        }
        field(6; ChangeRefNo; Text[250])
        {
            Caption = 'ChangeRefNo';
        }
        field(9; "Source Line ID"; RecordID)
        {
            Caption = 'Source Line ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(10; "Source Document ID"; RecordID)
        {
            Caption = 'Source Document ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(20; "Original Quantity"; Decimal)
        {
            Caption = 'Original Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(21; "New Quantity"; Decimal)
        {
            Caption = 'New Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(1000; ID; Integer)
        {
            AutoIncrement = false;
            Caption = 'ID';
            MinValue = 0;
            NotBlank = true;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; "New Date", ID)
        {
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure TransferToTransactionTable(var TimelineEvent: Record "Timeline Event"; var transactionTable: DotNet DataModel_TransactionDataTable)
    var
        transactionRow: DotNet DataModel_TransactionRow;
    begin
        transactionTable := transactionTable.TransactionDataTable;
        TimelineEvent.Reset();
        if TimelineEvent.Find('-') then
            repeat
                transactionRow := transactionTable.NewRow;
                transactionRow.RefNo := Format(TimelineEvent.ID);
                transactionRow.ChangeRefNo := TimelineEvent.ChangeRefNo;
                transactionRow.TransactionType := TimelineEvent."Transaction Type";
                transactionRow.Description := TimelineEvent.Description;
                transactionRow.OriginalDate := CreateDateTime(TimelineEvent."Original Date", DefaultTime);
                transactionRow.NewDate := CreateDateTime(TimelineEvent."New Date", DefaultTime);
                transactionRow.OriginalQuantity := TimelineEvent."Original Quantity";
                transactionRow.NewQuantity := TimelineEvent."New Quantity";
                transactionTable.Rows.Add(transactionRow);
            until (TimelineEvent.Next = 0);
    end;

    procedure DefaultTime(): Time
    begin
        exit(0T);
    end;
}

