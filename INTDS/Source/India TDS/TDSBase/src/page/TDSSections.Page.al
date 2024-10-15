page 18695 "TDS Sections"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    RefreshOnActivate = true;
    UsageCategory = Lists;
    DelayedInsert = true;
    InsertAllowed = true;
    SourceTable = "TDS Section";
    SourceTableView = sorting("presentation Order");
    CardPageId = "TDS Section Card";
    layout
    {
        area(Content)
        {
            repeater(General)
            {
                ShowAsTree = true;
                IndentationColumn = "Indentation Level";
                IndentationControls = Description;
                field(Code; Code)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = DescriptionStyle;
                    ToolTip = 'Specify the section codes as per the Income Tax Act of 1961 for eTDS Returns.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = DescriptionStyle;
                    ToolTip = 'Specifies the Section Description ';
                }
                field(ecode; ecode)
                {
                    Caption = 'eTDS';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify the section code to be used in the return.';
                }
            }
        }
        area(Factboxes)
        {
            part(Detail; "Section Details Factbox")
            {
                Caption = 'Detail';
                SubPageLink = Code = field(Code);
                ApplicationArea = Basic, Suite;
            }
        }
    }
    actions
    {
        area(Processing)
        {
            group(Page)
            {
                action(EditInExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Edit in Excel';
                    Image = Excel;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Send the data in the  page to an Excel file for analysis or editing';

                    trigger OnAction()
                    var
                        ODataUtility: Codeunit ODataUtility;
                        TDSSectionLbl: Label 'Code eq %1', Comment = '%1 = TDS Section Code';
                    begin
                        ODataUtility.EditWorksheetInExcel('Sections', CurrPage.ObjectId(false), StrSubstNo(TDSSectionLbl, Rec.Code));
                    end;
                }
                action(ClearFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Clear Filter';
                    Image = Process;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Select to clear all the filters which are currently applied for the current record.';

                    trigger OnAction()
                    begin
                        Rec.Reset();
                        CurrPage.Update();
                    end;
                }
                action("Add TDS Nature of Deduction")
                {
                    ApplicationArea = Basic, Suite;
                    Promoted = true;
                    Image = NewItem;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'View or add sub categories of TDS section for the record.';
                    trigger OnAction()
                    var
                        ToSection: Record "TDS Section";
                        SubSection: Record "TDS Section";
                    begin
                        ToSection.Init();

                        SubSection.Reset();
                        SubSection.SetCurrentKey("Section Order");
                        SubSection.SetRange("Parent Code", Code);
                        if SubSection.FindLast() then
                            ToSection."Section Order" := SubSection."Section Order" + 1
                        else
                            ToSection."Section Order" := 1;
                        ToSection.Code := format(Rec.Code) + '-' + format(ToSection."Section Order");
                        ToSection.Description := Rec.Description;
                        ToSection."Parent Code" := Rec.Code;
                        SubSection.Reset();
                        SubSection.SetCurrentKey("Presentation Order");
                        SubSection.SetRange("Parent Code", Code);
                        if SubSection.FindLast() then
                            ToSection."Presentation Order" := SubSection."Presentation Order" + 1
                        else
                            ToSection."Presentation Order" := Rec."Presentation Order" + 1;
                        ToSection."Indentation Level" := Rec."Indentation Level" + 1;
                        ToSection.Insert(true);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if "Parent Code" = '' then
            DescriptionStyle := 'Strong'
        else
            DescriptionStyle := 'Standard';
    end;

    var
        DescriptionStyle: Text;
}