﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

dotnet
{
    assembly("MockTest")
    {
        type("MockTest.MockAzureKeyVaultSecret.MockAzureKeyVaultSecretProvider"; "MockAzureKeyVaultSecretProvider")
        {
        }
    }

    assembly("Microsoft.Dynamics.Nav.AzureADGraphClient")
    {
        Version = '16.0.0.0';
        Culture = 'neutral';
        PublicKeyToken = '31bf3856ad364e35';

        type("Microsoft.Dynamics.Nav.AzureADGraphClient.MockGraphQuery"; "MockGraphQuery")
        {
        }
    }
}