page 5623 "FA Allocations"
{
    AutoSplitKey = true;
    Caption = 'FA Allocations';
    DataCaptionFields = "Code", "Allocation Type";
    PageType = Worksheet;
    SourceTable = "FA Allocation";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Account No."; "Account No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the account number to allocate to for the fixed asset allocation type on this line.';
                }
                field("Account Name"; "Account Name")
                {
                    ApplicationArea = FixedAssets;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the account on this allocation line.';
                }
                field("Allocation %"; "Allocation %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the percentage to use when allocating the amount for the allocation type.';
                }
            }
            group(Control18)
            {
                ShowCaption = false;
                field(AllocationPct; AllocationPct + "Allocation %" - xRec."Allocation %")
                {
                    ApplicationArea = All;
                    Caption = 'Allocation %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    ToolTip = 'Specifies the allocation percentage that has accumulated on the line.';
                    Visible = AllocationPctVisible;
                }
                field(TotalAllocationPct; TotalAllocationPct + "Allocation %" - xRec."Allocation %")
                {
                    ApplicationArea = All;
                    Caption = 'Total Alloc. %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    ToolTip = 'Specifies the total allocation percentage for the accounts in the FA Allocations window.';
                    Visible = TotalAllocationPctVisible;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                        CurrPage.SaveRecord;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateAllocationPct;
    end;

    trigger OnInit()
    begin
        TotalAllocationPctVisible := true;
        AllocationPctVisible := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateAllocationPct;
    end;

    var
        AllocationPct: Decimal;
        TotalAllocationPct: Decimal;
        ShowAllocationPct: Boolean;
        ShowTotalAllocationPct: Boolean;
        [InDataSet]
        AllocationPctVisible: Boolean;
        [InDataSet]
        TotalAllocationPctVisible: Boolean;

    local procedure UpdateAllocationPct()
    var
        TempFAAlloc: Record "FA Allocation";
    begin
        TempFAAlloc.CopyFilters(Rec);
        ShowTotalAllocationPct := TempFAAlloc.CalcSums("Allocation %");
        if ShowTotalAllocationPct then begin
            TotalAllocationPct := TempFAAlloc."Allocation %";
            if "Line No." = 0 then
                TotalAllocationPct := TotalAllocationPct + xRec."Allocation %";
        end;

        if "Line No." <> 0 then begin
            TempFAAlloc.SetRange("Line No.", 0, "Line No.");
            ShowAllocationPct := TempFAAlloc.CalcSums("Allocation %");
            if ShowAllocationPct then
                AllocationPct := TempFAAlloc."Allocation %";
        end else begin
            TempFAAlloc.SetRange("Line No.", 0, xRec."Line No.");
            ShowAllocationPct := TempFAAlloc.CalcSums("Allocation %");
            if ShowAllocationPct then begin
                AllocationPct := TempFAAlloc."Allocation %";
                TempFAAlloc.CopyFilters(Rec);
                TempFAAlloc := xRec;
                if TempFAAlloc.Next = 0 then
                    AllocationPct := AllocationPct + xRec."Allocation %";
            end;
        end;

        AllocationPctVisible := ShowAllocationPct;
        TotalAllocationPctVisible := ShowTotalAllocationPct;
    end;
}

