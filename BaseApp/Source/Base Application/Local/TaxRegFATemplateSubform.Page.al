page 17239 "Tax Reg. FA Template Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Tax Register Template";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field("Report Line Code"; Rec."Report Line Code")
                {
                    ToolTip = 'Specifies the report line code associated with the tax register template.';
                    Visible = false;
                }
                field("Link Tax Register No."; Rec."Link Tax Register No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies the link tax register number associated with the tax register template.';
                    Visible = false;
                }
                field("Sum Field No."; Rec."Sum Field No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies the sum field number associated with the tax register template.';
                    Visible = false;
                }
                field("Line Code"; Rec."Line Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line code associated with the tax register template.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = DescriptionEmphasize;
                    ToolTip = 'Specifies the description associated with the tax register template.';
                }
                field(Expression; Expression)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expression of the related XML element.';
                }
                field("FA Type"; Rec."FA Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the fixed asset type associated with the tax register template.';
                }
                field("Belonging to Manufacturing"; Rec."Belonging to Manufacturing")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the tax register template belongs to Production or to Nonproduction.';
                }
                field("Depreciation Group"; Rec."Depreciation Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the depreciation group associated with the tax register template.';
                }
                field(Period; Period)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period associated with the tax register template.';
                }
                field(Indentation; Indentation)
                {
                    ToolTip = 'Specifies the indentation of the line.';
                    Visible = false;
                }
                field(Bold; Bold)
                {
                    ToolTip = 'Specifies if you want the amounts in this line to be printed in bold.';
                    Visible = false;
                }
                field("Result on Disposal"; Rec."Result on Disposal")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the result on disposal associated with the tax register template.';
                }
                field("Depr. Bonus % Filter"; Rec."Depr. Bonus % Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the depreciation bonus percentage filter associated with the tax register template.';
                }
                field("Depr. Book Filter"; Rec."Depr. Book Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the depreciation book filter associated with the tax register template.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DepreciationBook: Record "Depreciation Book";
                    begin
                        if PAGE.RunModal(0, DepreciationBook) = ACTION::LookupOK then begin
                            Text := DepreciationBook.Code;
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
                field("Tax Difference Code Filter"; Rec."Tax Difference Code Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax difference code filter associated with the tax register template.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        TaxDifference: Record "Tax Difference";
                    begin
                        if PAGE.RunModal(0, TaxDifference) = ACTION::LookupOK then begin
                            Text := TaxDifference.Code;
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := 0;
        DescriptionOnFormat();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        "Expression Type" := "Expression Type"::SumField;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Expression Type" := "Expression Type"::SumField;
        InitFADeprBookFilter();
    end;

    var
        [InDataSet]
        DescriptionEmphasize: Boolean;
        [InDataSet]
        DescriptionIndent: Integer;

    local procedure DescriptionOnFormat()
    begin
        DescriptionIndent := Indentation;
        DescriptionEmphasize := Bold;
    end;
}

