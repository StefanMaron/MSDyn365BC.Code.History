report 11112 "Update VAT Statement Template"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Update VAT Statement Template';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number);
            MaxIteration = 1;

            trigger OnAfterGetRecord()
            var
                UpdateVATAT: Codeunit "Update VAT-AT";
                UpdateVATCH: Codeunit "Update VAT-CH";
            begin
                if Country = Country::Austria then begin
                    if TemplateName <> '' then
                        UpdateVATAT.UpdateVATStatementTemplate(TemplateName, TemplateDescription, AgricultureVATProdPostingGroups)
                    else
                        Error(SpecifyVATStatementTemplateNameErr);
                end else begin
                    if TemplateName <> '' then
                        UpdateVATCH.UpdateVATStatementTemplate(TemplateName, TemplateDescription)
                    else
                        Error(SpecifyVATStatementTemplateNameErr);
                end;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(VATStatementTemplateName; TemplateName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Statement Template Name';
                        TableRelation = "VAT Statement Template";
                        ToolTip = 'Specifies the VAT statement template name that you want to update, such as UVA-2009 or VAT-2010.';

                        trigger OnValidate()
                        begin
                            TemplateNameOnAfterValidate;
                        end;
                    }
                    field(Description; TemplateDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Description';
                        ToolTip = 'Specifies a description of the record.';
                    }
                    field(Country; Country)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Country';
                        ToolTip = 'Specifies the country.';

                        trigger OnValidate()
                        begin
                            UpdateTemplateDetails;
                        end;
                    }
                    field("Agriculture VAT Prod. Post. Gr."; AgricultureVATProdPostingGroups)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Product Posting Groups for fixed rate agricultural and forestry businesses';
                        Editable = false;

                        trigger OnAssistEdit()
                        var
                            VATProductPostingGroup: Record "VAT Product Posting Group";
                        begin
                            VATProductPostingGroup.LookupVATProductPostingGroupFilter(AgricultureVATProdPostingGroups);
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            UpdateTemplateDetails;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        TemplateName := 'UVA-2016';
        TemplateDescription := 'Österreichische USt ab 2016';
    end;

    var
        SpecifyVATStatementTemplateNameErr: Label 'Please specify a VAT Statement Template Name.';
        TemplateName: Code[10];
        TemplateDescription: Text[80];
        AgricultureVATProdPostingGroups: Text;
        Country: Option Switzerland,Austria;
        CHTemplateNameTxt: Label 'VAT-%1';
        CHTemplateDescrTxt: Label 'Swiss VAT Statement %1';
        AUTemplateNameTxt: Label 'UVA-2016';
        AUTemplateDescrTxt: Label 'Österreichische USt ab 2016';

    [Scope('OnPrem')]
    procedure UpdateTemplateDetails()
    begin
        if Country = Country::Austria then begin
            TemplateName := AUTemplateNameTxt;
            TemplateDescription := AUTemplateDescrTxt;
        end else begin
            TemplateName := StrSubstNo(CHTemplateNameTxt, Format(Date2DMY(WorkDate, 3)));
            TemplateDescription := StrSubstNo(CHTemplateDescrTxt, Format(Date2DMY(WorkDate, 3)));
        end;
    end;

    local procedure TemplateNameOnAfterValidate()
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        if VATStatementTemplate.Get(TemplateName) then
            TemplateDescription := VATStatementTemplate.Description
        else
            TemplateDescription := '';
    end;
}

