page 10704 "Transference Format"
{
    Caption = 'Transference Format';
    PageType = Worksheet;
    SourceTable = "AEAT Transference Format";

    layout
    {
        area(content)
        {
            field(VATStmtCode; VATStmtCode)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'VAT Stmt. Name';
                Lookup = true;
                TableRelation = "VAT Statement Name".Name;
                ToolTip = 'Specifies the name of the related VAT statement.';

                trigger OnValidate()
                begin
                    SetRange("VAT Statement Name", VATStmtCode);
                    VATStmtCodeOnAfterValidate();
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line number of the XML label that will be included in the VAT statement text file.';
                }
                field(Position; Position)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the position of the XML label that will be included in the VAT statement text file.';
                }
                field(Length; Length)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the field length of the XML label that will be included in the VAT statement text file.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line type of the XML label that will be included in the VAT statement text file.';
                }
                field(Subtype; Subtype)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line subtype of the XML label that will be included in the VAT statement text file.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the XML label that will be included in the VAT statement text file.';
                }
                field(Value; Value)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the field value of the XML label that will be included in the VAT statement text file.';
                }
                field(Box; Box)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the box number of the XML label that will be included in the VAT statement text file.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "VAT Statement Name" := VATStmtCode;
    end;

    trigger OnOpenPage()
    begin
        FeatureTelemetry.LogUptake('1000HV7', ESTelematicVATTok, Enum::"Feature Uptake Status"::Discovered);
        if "VAT Statement Name" <> '' then
            VATStmtCode := "VAT Statement Name"
        else begin
            VATSmtName.FindFirst();
            VATStmtCode := VATSmtName.Name;
        end;
    end;

    var
        VATSmtName: Record "VAT Statement Name";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ESTelematicVATTok: Label 'ES Create Templates for Telematic VAT Statements in Text File Format', Locked = true;
        VATStmtCode: Code[10];

    local procedure VATStmtCodeOnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

