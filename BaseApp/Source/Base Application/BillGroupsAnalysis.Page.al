page 7000020 "Bill Groups Analysis"
{
    Caption = 'Bill Groups Analysis';
    DataCaptionExpression = Caption;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Bill Group";

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field("Category Filter"; "Category Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a sort filter for the documents included in this bill group.';

                    trigger OnValidate()
                    begin
                        CategoryFilterOnAfterValidate;
                    end;
                }
            }
            group(Control3)
            {
                ShowCaption = false;
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the currency code for the bill group.';
                }
                field(DocCount; DocCount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of Documents';
                    Editable = false;
                    ToolTip = 'Specifies the number of documents included.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the sums of the documents included in the bill group.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount for all of the documents included in the bill group.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        UpdateStatistics;
    end;

    var
        Doc: Record "Cartera Doc.";
        DocCount: Integer;

    local procedure UpdateStatistics()
    begin
        Doc.SetRange(Type, Doc.Type::Receivable);
        Doc.SetRange("Collection Agent", Doc."Collection Agent"::Bank);
        Doc.SetRange("Bill Gr./Pmt. Order No.", "No.");
        CopyFilter("Global Dimension 1 Filter", Doc."Global Dimension 1 Code");
        CopyFilter("Global Dimension 2 Filter", Doc."Global Dimension 2 Code");
        CopyFilter("Category Filter", Doc."Category Code");
        CopyFilter("Due Date Filter", Doc."Due Date");
        DocCount := Doc.Count;
    end;

    local procedure CategoryFilterOnAfterValidate()
    begin
        UpdateStatistics;
    end;
}

