report 17371 "Create Positions from Budget"
{
    Caption = 'Create Positions from Budget';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("Position.Rate"; Position.Rate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Available Position Rate';
                        Editable = false;
                    }
                    field(PositionNumber; PositionNumber)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Number of Positions';

                        trigger OnValidate()
                        begin
                            UpdateRate;
                        end;
                    }
                    field(PositionRate; PositionRate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Position Rate';

                        trigger OnValidate()
                        begin
                            UpdateRate;
                        end;
                    }
                    field(RemPositionRate; RemPositionRate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Remaining Position Rate';
                        Editable = false;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            Position.TestField("No.");
            Position.TestField(Rate);
            Position.TestField(Status, Position.Status::Approved);
            PositionRate := 1;
            UpdateRate;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if RemPositionRate < 0 then
            Error(Text14701);

        if Confirm(Text14700, false, PositionNumber, PositionRate, Position."No.") then begin
            while PositionNumber > 0 do begin
                Position2.Init;
                Position2.TransferFields(Position, false);

                Position2."No." := '';
                Position2.Status := Position2.Status::Planned;
                Position2.Validate("Budgeted Position", false);
                Position2.Validate("Budgeted Position No.", Position."No.");
                Position2.Validate("No.", PositionNo);
                Position2.Status := Position2.Status::Planned;
                Position2.Validate(Rate, PositionRate);
                Position2."Created By User" := UserId;
                Position2."Creation Date" := Today;
                Position2."Approved By User" := '';
                Position2."Approval Date" := 0D;
                Position2."Closed By User" := '';
                Position2."Closing Date" := 0D;
                Position2.Insert(true);
                Position2.CopyContractTerms;

                PositionNumber := PositionNumber - 1;
                Position.Rate := Position.Rate - Position2.Rate;
            end;
            Position.Modify;
        end;
    end;

    var
        Position: Record Position;
        Position2: Record Position;
        PositionNumber: Integer;
        PositionRate: Decimal;
        PositionNo: Code[20];
        Text14700: Label '%1 position(s) with rate %2 will be created from budget position %3. Continue?';
        RemPositionRate: Decimal;
        Text14701: Label 'Remaining position rate cannot be negative.';

    [Scope('OnPrem')]
    procedure Set(NewPosition: Record Position)
    begin
        Position := NewPosition;
        Position.Get(Position."No.");
        Position.TestField("Budgeted Position", true);
    end;

    [Scope('OnPrem')]
    procedure UpdateRate()
    begin
        RemPositionRate :=
          Position.Rate - PositionNumber * PositionRate;
    end;
}

