report 742 "VAT Report Request Page"
{
    Caption = 'VAT Report Request Page';
    ProcessingOnly = true;

    dataset
    {
        dataitem("VAT Report Header"; "VAT Report Header")
        {

            trigger OnPostDataItem()
            begin
                "Created Date-Time" := CurrentDateTime();
                Modify();
            end;

            trigger OnPreDataItem()
            var
                VATStatementLine: Record "VAT Statement Line";
                VATStatementReportLine: Record "VAT Statement Report Line";
                VATStatementName: Record "VAT Statement Name";
                VATStatement: Report "VAT Statement";
                ColumnValue: Decimal;
            begin
                Copy(Rec);

                VATStatementName.SetRange("Statement Template Name", "Statement Template Name");
                VATStatementName.SetRange(Name, "Statement Name");
                VATStatementName.SetRange("Date Filter", "Start Date", "End Date");

                VATStatementName.CopyFilter("Date Filter", VATStatementLine."Date Filter");

                VATStatementLine.SetRange("Statement Template Name", "Statement Template Name");
                VATStatementLine.SetRange("Statement Name", "Statement Name");
                VATStatementLine.SetFilter("Box No.", '<>%1', '');
                VATStatementLine.FindSet;

                VATStatement.InitializeRequest(
                  VATStatementName, VATStatementLine, Selection, PeriodSelection, false, "Amounts in Add. Rep. Currency");

                VATStatementReportLine.SetRange("VAT Report No.", "No.");
                VATStatementReportLine.SetRange("VAT Report Config. Code", "VAT Report Config. Code");
                VATStatementReportLine.DeleteAll();

                repeat
                    VATStatement.CalcLineTotal(VATStatementLine, ColumnValue, 0);
                    if VATStatementLine."Print with" = VATStatementLine."Print with"::"Opposite Sign" then
                        ColumnValue := -ColumnValue;
                    VATStatementReportLine.Init();
                    VATStatementReportLine.Validate("VAT Report No.", "No.");
                    VATStatementReportLine.Validate("VAT Report Config. Code", "VAT Report Config. Code");
                    VATStatementReportLine.Validate("Line No.", VATStatementLine."Line No.");
                    VATStatementReportLine.Validate("Row No.", VATStatementLine."Row No.");
                    VATStatementReportLine.Validate(Description, VATStatementLine.Description);
                    VATStatementReportLine.Validate("Box No.", VATStatementLine."Box No.");
                    VATStatementReportLine.Validate(Amount, ColumnValue);
                    VATStatementReportLine.Insert();
                until VATStatementLine.Next = 0;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        ShowFilter = false;
        SourceTable = "VAT Report Header";

        layout
        {
            area(content)
            {
                group(Options)
                {
                    field(Selection; Selection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT entries';
                        OptionCaption = 'Open,Closed,Open and Closed';
                        ShowMandatory = true;
                        ToolTip = 'Specifies whether to include VAT entries based on their status. For example, Open is useful when submitting for the first time, Open and Closed is useful when resubmitting.';
                    }
                    field(PeriodSelection; PeriodSelection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT entries';
                        OptionCaption = 'Before and Within Period,Within Period';
                        ShowMandatory = true;
                        ToolTip = 'Specifies whether to include VAT entries only from the specified period, or also from previous periods within the specified year.';
                    }
                    field(VATStatementTemplate; "Statement Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Statement Template';
                        ShowMandatory = true;
                        TableRelation = "VAT Statement Template";
                        ToolTip = 'Specifies the VAT Statement to generate the VAT report.';
                    }
                    field(VATStatementName; "Statement Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Statement Name';
                        LookupPageID = "VAT Statement Names";
                        ShowMandatory = true;
                        TableRelation = "VAT Statement Name".Name WHERE("Statement Template Name" = FIELD("Statement Template Name"));
                        ToolTip = 'Specifies the VAT Statement to generate the VAT report.';
                    }
                    field("Period Year"; "Period Year")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = PeriodIsEditable;
                        ToolTip = 'Specifies the year of the reporting period.';
                    }
                    field("Period Type"; "Period Type")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = PeriodIsEditable;
                        ToolTip = 'Specifies the length of the reporting period.';
                    }
                    field("Period No."; "Period No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = PeriodIsEditable;
                        ToolTip = 'Specifies the specific reporting period to use.';
                    }
                    field("Start Date"; "Start Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = PeriodIsEditable;
                        Importance = Additional;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the first date of the reporting period.';
                    }
                    field("End Date"; "End Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = PeriodIsEditable;
                        Importance = Additional;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the last date of the reporting period.';
                    }
                    field("Amounts in ACY"; "Amounts in Add. Rep. Currency")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Amounts in Add. Reporting Currency';
                        Importance = Additional;
                        ToolTip = 'Specifies if you want to report amounts in the additional reporting currency.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            VATStatementTemplate: Record "VAT Statement Template";
            VATStatementName: Record "VAT Statement Name";
        begin
            CopyFilters("VAT Report Header");
            FindFirst;

            if VATStatementTemplate.Count = 1 then begin
                VATStatementTemplate.FindFirst;
                "Statement Template Name" := VATStatementTemplate.Name;
                Modify;

                VATStatementName.SetRange("Statement Template Name", VATStatementTemplate.Name);
                if VATStatementName.Count = 1 then begin
                    VATStatementName.FindFirst;
                    "Statement Name" := VATStatementName.Name;
                    Modify;
                end;
            end;

            PeriodIsEditable := "Return Period No." = '';
            OnAfterSetPeriodIsEditable(Rec, PeriodIsEditable);
        end;
    }

    labels
    {
    }

    var
        Selection: Option Open,Closed,"Open and Closed";
        PeriodSelection: Option "Before and Within Period","Within Period";
        [InDataSet]
        PeriodIsEditable: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPeriodIsEditable(VATReportHeader: Record "VAT Report Header"; var PeriodIsEditable: Boolean)
    begin
    end;
}

