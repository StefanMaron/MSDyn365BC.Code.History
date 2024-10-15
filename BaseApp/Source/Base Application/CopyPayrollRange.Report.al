report 17406 "Copy Payroll Range"
{
    Caption = 'Copy Payroll Range';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number);
            MaxIteration = 1;

            trigger OnAfterGetRecord()
            begin
                RangeLine.Reset();
                RangeLine.SetRange("Element Code", RangeHeader."Element Code");
                RangeLine.SetRange("Range Code", RangeHeader.Code);
                RangeLine.SetRange("Period Code", RangeHeader."Period Code");
                if RangeLine.FindSet then
                    repeat
                        RangeLine2.Init();
                        RangeLine2.TransferFields(RangeLine);
                        RangeLine2."Period Code" := NewPeriodCode;
                        RangeLine2.Insert();
                    until RangeLine.Next() = 0;

                RangeHeader."Period Code" := NewPeriodCode;
                RangeHeader.Insert();
            end;
        }
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
                    field(NewPeriodCode; NewPeriodCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Period';
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

    var
        RangeHeader: Record "Payroll Range Header";
        RangeLine: Record "Payroll Range Line";
        RangeLine2: Record "Payroll Range Line";
        NewPeriodCode: Code[10];

    [Scope('OnPrem')]
    procedure GetRangeHeader(NewRangeHeader: Record "Payroll Range Header")
    begin
        RangeHeader := NewRangeHeader;
    end;
}

