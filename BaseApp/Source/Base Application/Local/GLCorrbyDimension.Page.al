page 14945 "G/L Corr. by Dimension"
{
    Caption = 'G/L Corr. by Dimension';
    Editable = false;
    PageType = List;
    SourceTable = "G/L Correspondence";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Debit Account No."; Rec."Debit Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit account number associated with this correspondence.';
                }
                field("Credit Account No."; Rec."Credit Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit account number associated with this correspondence.';
                }
                field(CalculateAmount; CalcAmount())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount';
                    ToolTip = 'Specifies the amount.';

                    trigger OnDrillDown()
                    begin
                        GLCorrAnalysisViewEntry.SetRange("Debit Account No.", "Debit Account No.");
                        GLCorrAnalysisViewEntry.SetRange("Credit Account No.", "Credit Account No.");
                        PAGE.RunModal(PAGE::"G/L Corr. Analysis View Entr.", GLCorrAnalysisViewEntry);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    var
        GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry";

    [Scope('OnPrem')]
    procedure InitParameters(var SourceGLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry")
    begin
        GLCorrAnalysisViewEntry.Copy(SourceGLCorrAnalysisViewEntry);
        if GLCorrAnalysisViewEntry.FindSet() then
            repeat
                if not Get(GLCorrAnalysisViewEntry."Debit Account No.", GLCorrAnalysisViewEntry."Credit Account No.") then begin
                    "Debit Account No." := GLCorrAnalysisViewEntry."Debit Account No.";
                    "Credit Account No." := GLCorrAnalysisViewEntry."Credit Account No.";
                    Insert();
                end;
            until GLCorrAnalysisViewEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CalcAmount(): Decimal
    begin
        GLCorrAnalysisViewEntry.SetRange("Debit Account No.", "Debit Account No.");
        GLCorrAnalysisViewEntry.SetRange("Credit Account No.", "Credit Account No.");
        GLCorrAnalysisViewEntry.CalcSums(Amount);
        exit(GLCorrAnalysisViewEntry.Amount);
    end;
}

