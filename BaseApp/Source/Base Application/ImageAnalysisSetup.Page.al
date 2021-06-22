page 2020 "Image Analysis Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Image Analysis Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    Permissions = TableData "Azure AI Usage" = rimd;
    ShowFilter = false;
    SourceTable = "Image Analysis Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Api Uri"; "Api Uri")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'API URI';
                    ToolTip = 'Specifies the API URI for the Computer Vision account to use with Microsoft Cognitive Services.';

                    trigger OnValidate()
                    begin
                        if ("Api Uri" <> '') and (ApiKey <> '') then
                            SetInfiniteAccess;
                    end;
                }
                field("<Api Key>"; ApiKey)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'API Key';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the API key for the Computer Vision account to use with Microsoft Cognitive Services.';

                    trigger OnValidate()
                    begin
                        SetApiKey(ApiKey);

                        if ("Api Uri" <> '') and (ApiKey <> '') then
                            SetInfiniteAccess;
                    end;
                }
                field(LimitType; LimitType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Limit Type';
                    Editable = false;
                    ToolTip = 'Specifies the unit of time to limit the usage of the Computer Vision service.';
                }
                field(LimitValue; LimitValue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Limit Value';
                    Editable = false;
                    ToolTip = 'Specifies the number of images that can be analyzed per unit of time.';
                }
                field(NumberOfCalls; NumberOfCalls)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Analyses Performed';
                    Editable = false;
                    ToolTip = 'Specifies the number of images that have been analyzed per unit of time.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(SetupAction)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Computer Vision API Documentation';
                Image = LinkWeb;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Set up a Computer Vision account with Microsoft Cognitive Services to do image analysis with Dynamics 365.';

                trigger OnAction()
                begin
                    HyperLink('https://go.microsoft.com/fwlink/?linkid=848400');
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        AzureAIUsage: Record "Azure AI Usage";
    begin
        GetSingleInstance;
        if GetApiKey <> '' then
            ApiKey := '***';
        if ("Api Uri" <> '') and (ApiKey <> '') then
            AzureAIUsage.SetImageAnalysisIsSetup(true)
        else
            AzureAIUsage.SetImageAnalysisIsSetup(false);

        AzureAIUsage.GetSingleInstance(AzureAIUsage.Service::"Computer Vision");
        LimitType := AzureAIUsage."Limit Period";
        LimitValue := AzureAIUsage."Original Resource Limit";
        NumberOfCalls := AzureAIUsage."Total Resource Usage";
    end;

    var
        ApiKey: Text;
        LimitType: Option Year,Month,Day,Hour;
        LimitValue: Integer;
        NumberOfCalls: Integer;

    local procedure SetInfiniteAccess()
    var
        AzureAIUsage: Record "Azure AI Usage";
    begin
        AzureAIUsage.SetImageAnalysisIsSetup(true);
        AzureAIUsage.GetSingleInstance(AzureAIUsage.Service::"Computer Vision");
        LimitType := AzureAIUsage."Limit Period"::Year;
        AzureAIUsage."Limit Period" := AzureAIUsage."Limit Period"::Year;

        LimitValue := 999;
        AzureAIUsage."Original Resource Limit" := 999;
        AzureAIUsage.Modify();
    end;
}

