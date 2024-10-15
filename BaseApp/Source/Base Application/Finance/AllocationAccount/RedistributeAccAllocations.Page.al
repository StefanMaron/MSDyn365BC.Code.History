namespace Microsoft.Finance.AllocationAccount;

page 2678 "Redistribute Acc. Allocations"
{
    PageType = Worksheet;
    SourceTable = "Allocation Line";
    Caption = 'Change Allocations';
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            group(MainGroup)
            {
                ShowCaption = false;
                field(AmountToAllocate; AmountToAllocate)
                {
                    Caption = 'Original Amount to Allocate';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount to be allocated to the Destination Account.';
                    Editable = false;
                }
                field(PostingDate; PostingDate)
                {
                    Caption = 'Posting Date';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date on which the allocation is posted.';
                    Editable = false;
                }
                field(RemainingAmountToAllocate; DifferenceAmount)
                {
                    Caption = 'Remaining Amount to Allocate';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the remaining amount to be allocated to one of the lines.';
                    StyleExpr = DifferenceAmountStyle;
                    Editable = false;
                }
            }

            repeater(MainContent)
            {
                field(DestinationAccountType; Rec."Destination Account Type")
                {
                    Caption = 'Destination Account Type';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the Destination Account.';
                    
                    trigger OnValidate()
                    begin
                        UpdateDestinationAccountName();
                    end;
                }

                field(DestinationAccountNumber; Rec."Destination Account Number")
                {
                    Caption = 'Destination Account No.';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the Destination Account.';

                    trigger OnValidate()
                    begin
                        UpdateDestinationAccountName();
                    end;
                }

                field("Destination Account Name"; Rec."Destination Account Name")
                {
                    Caption = 'Destination Account Name';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the Destination Account.';
                    Editable = false;
                }
                field(Amount; Rec.Amount)
                {
                    Caption = 'Amount';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount to be allocated to the Destination Account.';

                    trigger OnValidate()
                    begin
                        CalculateDifference();
                    end;
                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            action(ResetToDefault)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reset to Default';
                Image = Restore;
#pragma warning disable AA0219
                ToolTip = 'Resets the allocation lines to the original allocation.';
#pragma warning restore AA0219

                Scope = Page;

    trigger OnAction()
    begin
        Rec.ResetToDefault(Rec, ParentSystemId, ParentTableId);
        Rec.Reset();
        Modified := false;
        if Rec.FindFirst() then;
        CurrPage.Update(false);
        DifferenceAmount := 0;
        DifferenceAmountStyle := '';
    end;
            }
            action(Dimensions)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Dimensions';
                Image = Dimensions;
                ShortCutKey = 'Shift+Ctrl+D';
#pragma warning disable AA0219
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';
#pragma warning restore AA0219

                trigger OnAction()
                begin
                    Rec.ShowDimensions();
                    if Rec."Dimension Set ID" <> xRec."Dimension Set ID" then begin
                        Modified := true;
                        Rec.Modify();
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(ResetToDefault_Promoted; ResetToDefault)
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }
    trigger OnOpenPage()
    begin
        Rec.GetOrGenerateAllocationLines(Rec, ParentSystemId, ParentTableId, AmountToAllocate, PostingDate);
        Rec.Reset();
        if Rec.FindFirst() then
            Rec.SetRange("Allocation Account No.", Rec."Allocation Account No.");
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateDestinationAccountName();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CalculateDifference();
        UpdateDestinationAccountName();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Modified := true;
        exit(true);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Modified := true;
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Modified := true;
        exit(true);
    end;

    internal procedure SetParentSystemId(NewParentSystemId: Guid)
    begin
        ParentSystemId := NewParentSystemId;
    end;

    internal procedure SetParentTableId(NewParentTableId: Integer)
    begin
        ParentTableId := NewParentTableId;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [CloseAction::Cancel, CloseAction::LookupCancel] then
            exit(true);

        if Modified then
            if Confirm(SaveChangesQst) then
                Rec.SaveChangesToAllocationLines(Rec, ParentSystemId, ParentTableId, AmountToAllocate);

        exit(true);
    end;

    local procedure CalculateDifference()
    var
        TotalsAllocationLine: Record "Allocation Line";
    begin
        TotalsAllocationLine.Copy(Rec, true);
        TotalsAllocationLine.CalcSums(Amount);
        DifferenceAmount := AmountToAllocate - TotalsAllocationLine.Amount;
        if DifferenceAmount <> 0 then
            DifferenceAmountStyle := 'Attention'
        else
            DifferenceAmountStyle := '';
    end;

    local procedure UpdateDestinationAccountName()
    var
        AllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        Rec."Destination Account Name" := AllocAccountDistribution.LookupDistributionAccountName(Rec."Destination Account Type", Rec."Destination Account Number");
    end;

    var
        DifferenceAmountStyle: Text;
        DifferenceAmount: Decimal;
        AmountToAllocate: Decimal;
        PostingDate: Date;
        ParentSystemId: Guid;
        ParentTableId: Integer;
        Modified: Boolean;
        SaveChangesQst: Label 'Do you want to save the changes?';
}