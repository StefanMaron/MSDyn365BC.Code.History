codeunit 2002 "Azure AI Tracing"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        AzureAICategoryTxt: Label 'AL Azure AI', Locked = true;
        TraceImageAnalysisSuccessTagsTxt: Label 'Number of Image Analysis calls: %1;Limit: %2;Period type: %3;Execution time: %4 ms;Confidence: %5.', Locked = true;
        AnalysisStartTime: DateTime;
        TraceImageAnalysisSuccessTxt: Label 'Number of Image Analysis calls: %1;Limit: %2;Period type: %3;Execution time: %4 ms.', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, 2020, 'OnBeforeImageAnalysis', '', false, false)]
    local procedure TraceImageAnalysisStart(var Sender: Codeunit "Image Analysis Management")
    begin
        AnalysisStartTime := CurrentDateTime;
    end;

    [EventSubscriber(ObjectType::Codeunit, 2020, 'OnAfterImageAnalysis', '', false, false)]
    local procedure TraceImageAnalysisEnd(var Sender: Codeunit "Image Analysis Management"; ImageAnalysisResult: Codeunit "Image Analysis Result")
    var
        AzureAIUsage: Record "Azure AI Usage";
        LastError: Text;
        IsUsageLimitError: Boolean;
        LimitType: Option Year,Month,Day,Hour;
        LimitValue: Integer;
        Message: Text;
        AnalysisDuration: Integer;
        AnalysisType: Option Tags,Faces,Color;
        NoOfCalls: Integer;
    begin
        if Sender.GetLastError(LastError, IsUsageLimitError) then
            SendTraceTag('000015X', AzureAICategoryTxt, VERBOSITY::Error, LastError, DATACLASSIFICATION::SystemMetadata)
        else begin
            Sender.GetLimitParams(LimitType, LimitValue);

            AnalysisDuration := CurrentDateTime - AnalysisStartTime;
            ImageAnalysisResult.GetLatestAnalysisType(AnalysisType);
            NoOfCalls := AzureAIUsage.GetTotalProcessingTime(AzureAIUsage.Service::"Computer Vision");
            if AnalysisType = AnalysisType::Tags then
                Message := StrSubstNo(TraceImageAnalysisSuccessTagsTxt,
                    NoOfCalls, LimitValue, LimitType, AnalysisDuration,
                    ImageAnalysisResult.TagConfidence(1))
            else
                Message := StrSubstNo(TraceImageAnalysisSuccessTxt,
                    NoOfCalls, LimitValue, LimitType, AnalysisDuration);

            SendTraceTag('000015Y', AzureAICategoryTxt, VERBOSITY::Normal, Message, DATACLASSIFICATION::SystemMetadata);
        end;
    end;
}

