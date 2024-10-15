// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Text;

using System;
using System.Utilities;
using System.AI;
using System.Azure.KeyVault;

/// <summary>
/// Implements functionality to handle text suggestions.
/// </summary>
codeunit 2012 "Entity Text Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Decides visibility on pages
    /// </summary>
    procedure IsEnabled(Silent: Boolean): Boolean
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
    begin
        exit(AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"Entity Text", Silent));
    end;

    procedure CanSuggest(): Boolean
    var
        EntityTextAOAISettings: Codeunit "Entity Text AOAI Settings";
    begin
        if not EntityTextAOAISettings.IsEnabled(true) then
            exit(false);

        exit(HasPromptInfo());
    end;

    [NonDebuggable]
    procedure GenerateSuggestion(Facts: Dictionary of [Text, Text]; Tone: Enum "Entity Text Tone"; TextFormat: Enum "Entity Text Format"; TextEmphasis: Enum "Entity Text Emphasis"; CallerModuleInfo: ModuleInfo): Text
    var
        SystemPrompt: Text;
        UserPrompt: Text;
        Suggestion: Text;
    begin
        if not IsEnabled(true) then
            Error(CapabilityDisabledErr);
        if not CanSuggest() then
            Error(CannotGenerateErr);
        BuildPrompts(Facts, Tone, TextFormat, TextEmphasis, SystemPrompt, UserPrompt);

        Session.LogMessage('0000JVG', TelemetryGenerationRequestedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);

        Suggestion := GenerateAndReviewCompletion(SystemPrompt, UserPrompt, TextFormat, Facts, CallerModuleInfo, Tone, TextEmphasis);

        exit(Suggestion);
    end;

    procedure InsertSuggestion(SourceTableId: Integer; SourceSystemId: Guid; SourceScenario: Enum "Entity Text Scenario"; SuggestedText: Text)
    var
        EntityText: Record "Entity Text";
    begin
        InsertSuggestion(SourceTableId, SourceSystemId, SourceScenario, SuggestedText, EntityText);
    end;

    procedure InsertSuggestion(SourceTableId: Integer; SourceSystemId: Guid; SourceScenario: Enum "Entity Text Scenario"; SuggestedText: Text; var EntityText: Record "Entity Text")
    begin
        EntityText.Init();
        EntityText.Company := CopyStr(CompanyName(), 1, MaxStrLen(EntityText.Company));
        EntityText."Source Table Id" := SourceTableId;
        EntityText."Source System Id" := SourceSystemId;
        EntityText.Scenario := SourceScenario;
        SetText(EntityText, SuggestedText);

        if not EntityText.Insert() then
            EntityText.Modify();

        Session.LogMessage('0000JVH', StrSubstNo(TelemetrySuggestionCreatedTxt, Format(SourceTableId), Format(SourceScenario)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);
    end;

    procedure SetText(var EntityText: Record "Entity Text"; Content: Text)
    var
        Regex: Codeunit Regex;
        HttpUtility: DotNet HttpUtility;
        OutStr: OutStream;
        ContentNoTags: Text;
        ContentLines: List of [Text];
        ContentLine: Text;
    begin
        Clear(EntityText.Text);
        EntityText.Text.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(Content);

        // naively remove tags
        ContentLines := Regex.Replace(Content, '<br */?>', '\').Split('\');
        foreach ContentLine in ContentLines do begin
            ContentLine := Regex.Replace(ContentLine, '<[^>]+>', '');
            ContentLine := HttpUtility.HtmlDecode(ContentLine);

            if ContentLine <> '' then
                ContentNoTags += ContentLine + '\';
        end;

        ContentNoTags := DelChr(ContentNoTags, '>', ' \');

        EntityText."Preview Text" := CopyStr(ContentNoTags, 1, MaxStrLen(EntityText."Preview Text"));
    end;

    procedure GetText(var EntityText: Record "Entity Text"): Text
    var
        InStr: InStream;
        Result: Text;
    begin
        EntityText.CalcFields(Text);
        EntityText.Text.CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(Result);

        exit(Result);
    end;

    procedure GetText(TableId: Integer; SystemId: Guid; EntityTextScenario: Enum "Entity Text Scenario"): Text
    var
        EntityText: Record "Entity Text";
        Result: Text;
    begin
        if EntityText.Get(CompanyName(), TableId, SystemId, EntityTextScenario) then
            Result := GetText(EntityText);

        exit(Result);
    end;

    procedure SetEntityTextAuthorization(NewEndpoint: Text; NewDeployment: Text; NewApiKey: SecretText)
    begin
        Endpoint := NewEndpoint;
        Deployment := NewDeployment;
        ApiKey := NewApiKey;
    end;

    [NonDebuggable]
    local procedure BuildPrompts(var Facts: Dictionary of [Text, Text]; Tone: Enum "Entity Text Tone"; TextFormat: Enum "Entity Text Format"; TextEmphasis: Enum "Entity Text Emphasis"; var SystemPrompt: Text; var UserPrompt: Text)
    var
        EntityTextAOAISettings: Codeunit "Entity Text AOAI Settings";
        PromptInfo: JsonObject;
        SystemPromptJson: JsonToken;
        UserPromptJson: JsonToken;
        FactsList: Text;
        LanguageName: Text;
        Category: Text;
    begin
        FactsList := BuildFacts(Facts, Category, TextFormat);
        LanguageName := EntityTextAOAISettings.GetLanguageName();

        PromptInfo := GetPromptInfo();
        PromptInfo.Get('system', SystemPromptJson);
        PromptInfo.Get('user', UserPromptJson);

        SystemPrompt := BuildSinglePrompt(SystemPromptJson.AsObject(), LanguageName, FactsList, Category, Tone, TextFormat, TextEmphasis);
        UserPrompt := BuildSinglePrompt(UserPromptJson.AsObject(), LanguageName, FactsList, Category, Tone, TextFormat, TextEmphasis);
    end;

    [NonDebuggable]
    local procedure BuildSinglePrompt(PromptInfo: JsonObject; LanguageName: Text; FactsList: Text; Category: Text; Tone: Enum "Entity Text Tone"; TextFormat: Enum "Entity Text Format"; TextEmphasis: Enum "Entity Text Emphasis") Prompt: Text
    var
        PromptHints: JsonToken;
        PromptOrder: JsonToken;
        PromptHint: JsonToken;
        HintName: Text;
        NewLineChar: Char;
        PromptIndex: Integer;
    begin
        NewLineChar := 10;

        PromptInfo.Get('prompt', PromptHints);
        PromptInfo.Get('order', PromptOrder);

        foreach PromptHint in PromptOrder.AsArray() do begin
            HintName := PromptHint.AsValue().AsText();
            if PromptHints.AsObject().Get(HintName, PromptHint) then begin
                // found the hint
                if PromptHint.IsArray() then begin
                    PromptIndex := 0; // default value
                    case HintName of
                        'tone':
                            PromptIndex := Tone.AsInteger();
                        'format':
                            PromptIndex := TextFormat.AsInteger();
                        'emphasis':
                            PromptIndex := TextEmphasis.AsInteger();
                    end;

                    if not PromptHint.AsArray().Get(PromptIndex, PromptHint) then
                        PromptHint.AsArray().Get(0, PromptHint);
                end;

                Prompt += StrSubstNo(PromptHint.AsValue().AsText(), NewLineChar, LanguageName, FactsList, Category);
            end;
        end;
    end;

    [NonDebuggable]
    local procedure GetPromptInfo(): JsonObject
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        PromptObject: JsonObject;
        PromptObjectText: Text;
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(PromptObjectKeyTxt, PromptObjectText) then
            Error(PromptNotFoundErr);

        if not PromptObject.ReadFrom(PromptObjectText) then
            Error(PromptFormatInvalidErr);

        if (not PromptObject.Contains('user')) or (not PromptObject.Contains('system')) then
            Error(PromptFormatMissingPropsErr);

        exit(PromptObject);
    end;

    [TryFunction]
    [NonDebuggable]
    procedure HasPromptInfo()
    begin
        GetPromptInfo();
    end;

    [NonDebuggable]
    local procedure BuildFacts(var Facts: Dictionary of [Text, Text]; var Category: Text; TextFormat: Enum "Entity Text Format"): Text
    var
        FactKey: Text;
        FactValue: Text;
        FactsList: Text;
        NewLineChar: Char;
        MaxFacts: Integer;
        TotalFacts: Integer;
        MaxFactLength: Integer;
    begin
        NewLineChar := 10;
        TotalFacts := Facts.Count();
        if TotalFacts = 0 then
            Error(NoFactsErr);

        if TotalFacts < 2 then
            Error(MinFactsErr);

        if (TotalFacts < 4) and (TextFormat <> TextFormat::Tagline) then
            Error(NotEnoughFactsForFormatErr);

        MaxFacts := 20;
        MaxFactLength := 250;
        if TotalFacts > MaxFacts then
            Session.LogMessage('0000JWA', StrSubstNo(TelemetryPromptManyFactsTxt, Format(Facts.Count()), MaxFacts), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);

        TotalFacts := 0;
        foreach FactKey in Facts.Keys() do begin
            if TotalFacts < MaxFacts then begin
                Facts.Get(FactKey, FactValue);
                FactKey := FactKey.Replace(NewLineChar, '').Trim();
                FactValue := FactValue.Replace(NewLineChar, '').Trim();
                if (Category = '') and FactKey.Contains('Category') then
                    Category := FactValue
                else
                    FactsList += StrSubstNo(FactTemplateTxt, CopyStr(FactKey, 1, MaxFactLength), CopyStr(FactValue, 1, MaxFactLength), NewLineChar);
            end;

            TotalFacts += 1;
        end;

        exit(FactsList);
    end;

    [NonDebuggable]
    local procedure GenerateAndReviewCompletion(SystemPrompt: Text; UserPrompt: Text; TextFormat: Enum "Entity Text Format"; Facts: Dictionary of [Text, Text]; CallerModuleInfo: ModuleInfo; Tone: Enum "Entity Text Tone"; TextEmphasis: Enum "Entity Text Emphasis"): Text
    var
        Completion: Text;
        CompletionTag: Text;
        CompletionPar: Text;
        MaxAttempts: Integer;
        Attempt: Integer;
    begin
        MaxAttempts := 5;
        for Attempt := 0 to MaxAttempts do begin
            if TextFormat = TextFormat::TaglineParagraph then begin
                BuildPrompts(Facts, Tone, TextFormat::Tagline, TextEmphasis, SystemPrompt, UserPrompt);
                CompletionTag := GenerateCompletion(SystemPrompt, UserPrompt, CallerModuleInfo);

                BuildPrompts(Facts, Tone, TextFormat::Paragraph, TextEmphasis, SystemPrompt, UserPrompt);
                CompletionPar := GenerateCompletion(SystemPrompt, UserPrompt, CallerModuleInfo);
                Completion := CompletionTag + EncodedNewlineTok + EncodedNewlineTok + CompletionPar;
            end
            else
                Completion := GenerateCompletion(SystemPrompt, UserPrompt, CallerModuleInfo);

            if (not CompletionContainsPrompt(Completion, SystemPrompt)) and IsGoodCompletion(Completion, TextFormat, Facts) then
                exit(Completion);

            Sleep(500);
            Session.LogMessage('0000LVP', StrSubstNo(TelemetryGenerationRetryTxt, Attempt + 1), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);
        end;

        // this completion is of low quality
        Session.LogMessage('0000JYB', TelemetryLowQualityCompletionTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);

        exit('');
    end;

    [NonDebuggable]
    local procedure CompletionContainsPrompt(Completion: Text; Prompt: Text): Boolean
    var
        PromptSentences: List of [Text];
        PromptSentence: Text;
    begin
        PromptSentences := Prompt.Split('.');

        Completion := Completion.ToLower();
        foreach PromptSentence in PromptSentences do begin
            PromptSentence := PromptSentence.Trim().ToLower();

            if PromptSentence <> '' then
                if Completion.Contains(PromptSentence) then begin
                    Session.LogMessage('0000JZG', StrSubstNo(TelemetryCompletionHasPromptTxt, PromptSentence), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);
                    exit(true);
                end;
        end;

        exit(false);
    end;

    [NonDebuggable]
    local procedure IsGoodCompletion(var Completion: Text; TextFormat: Enum "Entity Text Format"; Facts: Dictionary of [Text, Text]): Boolean
    var
        TempMatches: Record Matches temporary;
        Regex: Codeunit Regex;
        SplitCompletion: List of [Text];
        FactKey: Text;
        FactValue: Text;
        CandidateNumber: Text;
        FoundNumber: Boolean;
        FormatValid: Boolean;
    begin
        if Completion = '' then begin
            Session.LogMessage('0000JWJ', TelemetryCompletionEmptyTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);
            exit(false);
        end;

        if Completion.ToLower().StartsWith('tagline:') then begin
            Session.LogMessage('0000JYD', TelemetryTaglineCleanedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);
            Completion := CopyStr(Completion, 9).Trim();
        end;
        FormatValid := true;
        case TextFormat of
            TextFormat::TaglineParagraph:
                begin
                    SplitCompletion := Completion.Split(EncodedNewlineTok + EncodedNewlineTok);
                    FormatValid := SplitCompletion.Count() = 2; // a tagline + paragraph must contain an empty line
                end;
            TextFormat::Paragraph:
                FormatValid := (not Completion.Contains(EncodedNewlineTok + EncodedNewlineTok)); // multiple paragraphs should be avoided
            TextFormat::Tagline:
                FormatValid := not Completion.Contains(EncodedNewlineTok); // a tagline should not have any newline
            TextFormat::Brief:
                FormatValid := Completion.Contains(EncodedNewlineTok + EncodedNewlineTok) and (Completion.Contains(EncodedNewlineTok + '-') or Completion.Contains(EncodedNewlineTok + '•')); // the brief should contain a pargraph and a list
        end;

        if not FormatValid then begin
            Session.LogMessage('0000JYC', StrSubstNo(TelemetryCompletionInvalidFormatTxt, TextFormat), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);
            exit(false);
        end;

        // check the facts
        Regex.Match(Completion, '(?<!\S)(\d*\.?\d+)(?!\S)', TempMatches); // extract numbers
        if not TempMatches.FindSet() then
            exit(true); // no numbers to validate

        repeat
            CandidateNumber := TempMatches.ReadValue();
            FoundNumber := false;
            foreach FactKey in Facts.Keys() do
                if not FoundNumber then
                    if FactKey.Contains(CandidateNumber) then
                        FoundNumber := true
                    else begin
                        FactValue := Facts.Get(FactKey);
                        if FactValue.Contains(CandidateNumber) then
                            FoundNumber := true;
                    end;

            if not FoundNumber then begin
                Session.LogMessage('0000JYE', StrSubstNo(TelemetryCompletionInvalidNumberTxt, CandidateNumber), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);
                exit(false); // made up number
            end;
        until TempMatches.Next() = 0;

        if Completion.Contains(StrSubstNo(NoteParagraphTxt, EncodedNewlineTok)) or Completion.Contains(StrSubstNo(TranslationParagraphTxt, EncodedNewlineTok)) then begin
            Session.LogMessage('0000LHZ', TelemetryCompletionExtraTextTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);
            exit(false);
        end;

        exit(true);
    end;

    [NonDebuggable]
    local procedure GenerateCompletion(SystemPrompt: Text; UserPrompt: Text; CallerModuleInfo: ModuleInfo): Text
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        EntityTextAOAISettings: Codeunit "Entity Text AOAI Settings";
        AOAIDeployments: Codeunit "AOAI Deployments";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAICompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        HttpUtility: DotNet HttpUtility;
        Result: Text;
        NewLineChar: Char;
        EntityTextModuleInfo: ModuleInfo;
    begin
        NewLineChar := 10;

        NavApp.GetCurrentModuleInfo(EntityTextModuleInfo);
        if (not (Endpoint = '')) and (not (Deployment = ''))
        then
            AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", Endpoint, Deployment, ApiKey)
        else
            if (not IsNullGuid(CallerModuleInfo.Id())) and (CallerModuleInfo.Publisher() = EntityTextModuleInfo.Publisher()) then
                AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", AOAIDeployments.GetGPT35TurboLatest())
            else begin
                Session.LogMessage('0000LJB', TelemetryNoAuthorizationHandlerTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryLbl);
                Error(NoAuthorizationHandlerErr);
            end;

        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Entity Text");

        AOAICompletionParams.SetMaxTokens(2500);
        AOAICompletionParams.SetTemperature(0.7);
        AOAIChatMessages.SetPrimarySystemMessage(SystemPrompt);
        AOAIChatMessages.AddUserMessage(UserPrompt);

        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAICompletionParams, AOAIOperationResponse);
        if not AOAIOperationResponse.IsSuccess() then begin
            Clear(Result);
            Error(CompletionDeniedPhraseErr);
        end;

        Result := HttpUtility.HtmlEncode(AOAIChatMessages.GetLastMessage());
        Result := Result.Replace(NewLineChar, EncodedNewlineTok);

        if EntityTextAOAISettings.ContainsWordsInDenyList(Result) then begin
            Clear(Result);
            Error(CompletionDeniedPhraseErr);
        end;

        exit(Result);
    end;

    var
        Endpoint: Text;
        Deployment: Text;
        ApiKey: SecretText;
        PromptObjectKeyTxt: Label 'AOAI-Prompt-23', Locked = true;
        FactTemplateTxt: Label '- %1: %2%3', Locked = true;
        EncodedNewlineTok: Label '<br />', Locked = true;
        NoteParagraphTxt: Label '%1Note:%1', Locked = true, Comment = 'This constant is used to limit the cases when the model goes out of format and must stay in English only.';
        TranslationParagraphTxt: Label 'Translation:%1', Locked = true, Comment = 'This constant is used to limit the cases when the model goes out of format and must stay in English only.';
        NoFactsErr: Label 'There''s no information available to draft a text from.';
        CannotGenerateErr: Label 'Text cannot be generated. Please check your configuration and contact your partner.';
        CapabilityDisabledErr: Label 'Sorry, your Copilot isn''t activated for Entity Text. Contact the system administrator.';
        MinFactsErr: Label 'There''s not enough information available to draft a text. Please provide more.';
        NotEnoughFactsForFormatErr: Label 'There''s not enough information available to draft a text for the chosen format. Please provide more, or choose another format.';
        PromptNotFoundErr: Label 'The prompt definition could not be found.';
        PromptFormatInvalidErr: Label 'The prompt definition is in an invalid format.';
        CompletionDeniedPhraseErr: Label 'Sorry, we could not generate a good suggestion for this. Review the information provided, consider your choice of words, and try again.';
        PromptFormatMissingPropsErr: Label 'Required properties are missing from the prompt definition.';
        NoAuthorizationHandlerErr: Label 'There was no handler to provide authorization information for the suggestion. Contact your partner.';
        TelemetryCategoryLbl: Label 'Entity Text', Locked = true;
        TelemetryGenerationRequestedTxt: Label 'New suggestion requested.', Locked = true;
        TelemetrySuggestionCreatedTxt: Label 'A new suggestion was generated for table %1, scenario %2', Locked = true;
        TelemetryCompletionEmptyTxt: Label 'The returned completion was empty.', Locked = true;
        TelemetryLowQualityCompletionTxt: Label 'Failed to generate a good quality completion, returning a low quality one.', Locked = true;
        TelemetryCompletionInvalidFormatTxt: Label 'The format %1 was requested, but the completion format did not pass validation.', Locked = true;
        TelemetryCompletionHasPromptTxt: Label 'The completion contains this sentence from the prompt: %1', Locked = true;
        TelemetryTaglineCleanedTxt: Label 'Trimmed a completion', Locked = true;
        TelemetryCompletionInvalidNumberTxt: Label 'A number was found in the completion (%1) that did not exist in the facts.', Locked = true;
        TelemetryCompletionExtraTextTxt: Label 'The completion contains a Translation or Note section.', Locked = true;
        TelemetryPromptManyFactsTxt: Label 'There are %1 facts defined, they will be limited to %2.', Locked = true;
        TelemetryNoAuthorizationHandlerTxt: Label 'Entity Text authorization was not set.', Locked = true;
        TelemetryGenerationRetryTxt: Label 'Retrying text generation, attempt: %1', Locked = true;
}