page 17281 "Tax Reg. Norm Template Setup"
{
    AutoSplitKey = true;
    Caption = 'Norm Template Setup';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Tax Reg. Norm Template Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field("Line Type"; Rec."Line Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line type associated with the norm template line.';
                }
                field("Line Code"; Rec."Line Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line code associated with the norm template line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = DescriptionEmphasize;
                    ToolTip = 'Specifies the description associated with the norm template line.';
                }
                field("Expression Type"; Rec."Expression Type")
                {
                    ApplicationArea = Basic, Suite;
                    HideValue = ExpressionTypeHideValue;
                    ToolTip = 'Specifies how the related tax calculation term is named, such as Plus/Minus, Multiply/Divide, and Compare.';
                }
                field("Link Group Code"; Rec."Link Group Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the link group code associated with the norm template line.';
                }
                field(Expression; Expression)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expression of the related XML element.';
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
                field("Rounding Precision"; Rec."Rounding Precision")
                {
                    ToolTip = 'Specifies the interval that you want to use as the rounding difference.';
                    Visible = false;
                }
                field(Period; Period)
                {
                    ToolTip = 'Specifies the period associated with the norm template line.';
                    Visible = false;
                }
                field("Jurisdiction Code"; Rec."Jurisdiction Code")
                {
                    ToolTip = 'Specifies the jurisdiction code associated with the norm template line.';
                    Visible = false;
                }
                field("Dimensions Filters"; Rec."Dimensions Filters")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    HideValue = DimensionsFiltersHideValue;
                    ToolTip = 'Specifies the dimension that the data is filtered by.';

                    trigger OnAssistEdit()
                    begin
                        CurrPage.SaveRecord();
                        Commit();
                        DimensionsFilters();
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
                action(Check)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Check';
                    Image = CheckList;

                    trigger OnAction()
                    begin
                        GeneralTermMgt.CheckTaxRegLink(false, "Norm Jurisdiction Code", DATABASE::"Tax Reg. Norm Template Line");
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DimensionsFiltersHideValue := false;
        ExpressionTypeHideValue := false;
        DescriptionIndent := 0;
        DescriptionOnFormat();
        ExpressionTypeOnFormat();
        DimensionsFiltersOnFormat(Format("Dimensions Filters"));
    end;

    var
        Text1001: Label 'Present';
        GeneralTermMgt: Codeunit "Tax Register Term Mgt.";
        [InDataSet]
        DescriptionEmphasize: Boolean;
        [InDataSet]
        DescriptionIndent: Integer;
        [InDataSet]
        ExpressionTypeHideValue: Boolean;
        [InDataSet]
        DimensionsFiltersHideValue: Boolean;

    [Scope('OnPrem')]
    procedure DimensionsFilters()
    var
        NormDimFilter: Record "Tax Reg. Norm Dim. Filter";
        GLSetup: Record "General Ledger Setup";
    begin
        if ("Line No." <> 0) and ("Expression Type" = "Expression Type"::Term) then begin
            GLSetup.Get();
            if (GLSetup."Global Dimension 1 Code" <> '') or
               (GLSetup."Global Dimension 2 Code" <> '')
            then begin
                NormDimFilter.FilterGroup(2);
                NormDimFilter.SetRange("Norm Jurisdiction Code", "Norm Jurisdiction Code");
                NormDimFilter.SetRange("Norm Group Code", "Norm Group Code");
                case true of
                    (GLSetup."Global Dimension 1 Code" <> '') and (GLSetup."Global Dimension 2 Code" <> ''):
                        NormDimFilter.SetFilter("Dimension Code", '%1|%2',
                          GLSetup."Global Dimension 1 Code", GLSetup."Global Dimension 2 Code");
                    (GLSetup."Global Dimension 1 Code" <> ''):
                        NormDimFilter.SetRange("Dimension Code", GLSetup."Global Dimension 1 Code");
                    else
                        NormDimFilter.SetRange("Dimension Code", GLSetup."Global Dimension 2 Code");
                end;
                NormDimFilter.FilterGroup(0);
                NormDimFilter.SetRange("Line No.", "Line No.");
                PAGE.RunModal(0, NormDimFilter);
            end else
                GLSetup.TestField("Global Dimension 1 Code");
        end;
    end;

    local procedure DescriptionOnFormat()
    begin
        DescriptionIndent := Indentation;
        DescriptionEmphasize := Bold;
    end;

    local procedure ExpressionTypeOnFormat()
    begin
        if "Expression Type" = "Expression Type"::Norm then
            ExpressionTypeHideValue := true;
    end;

    local procedure DimensionsFiltersOnFormat(Text: Text[1024])
    begin
        if "Dimensions Filters" then
            Text := Text1001
        else
            DimensionsFiltersHideValue := true;
    end;
}

