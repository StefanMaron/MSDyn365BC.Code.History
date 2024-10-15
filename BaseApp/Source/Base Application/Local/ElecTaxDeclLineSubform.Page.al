page 11413 "Elec. Tax Decl. Line Subform"
{
    Caption = 'Lines';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Elec. Tax Declaration Line";

    layout
    {
        area(content)
        {
            repeater(Control1000000)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the XML element or XML attribute.';
                }
                field(Data; Data)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the data of the XML element or XML attribute.';
                }
                field("Line Type"; Rec."Line Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the Elec. Tax Declaration Line contains data of an XML element or XML attribute.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        NameOnFormat();
    end;

    trigger OnOpenPage()
    begin
        SetRange("Line Type", "Line Type"::Element);
    end;

    var
        [InDataSet]
        NameEmphasize: Boolean;
        [InDataSet]
        NameIndent: Integer;

    local procedure NameOnFormat()
    begin
        NameIndent := "Indentation Level";
        NameEmphasize := "Line Type" = "Line Type"::Element;
    end;
}

