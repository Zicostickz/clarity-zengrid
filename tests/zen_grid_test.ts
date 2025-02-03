import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can record a valid entry",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('zen_grid', 'record-entry', [
        types.uint(3),
        types.some(types.utf8("Feeling good today"))
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk();
  },
});

Clarinet.test({
  name: "Cannot record invalid score",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('zen_grid', 'record-entry', [
        types.uint(6),
        types.some(types.utf8("Invalid score"))
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectErr(types.uint(102)); // ERR-INVALID-SCORE
  },
});

Clarinet.test({
  name: "Cannot record multiple entries same day",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('zen_grid', 'record-entry', [
        types.uint(3),
        types.some(types.utf8("First entry"))
      ], wallet1.address),
      Tx.contractCall('zen_grid', 'record-entry', [
        types.uint(4),
        types.some(types.utf8("Second entry"))
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk();
    block.receipts[1].result.expectErr(types.uint(103)); // ERR-ALREADY-RECORDED-TODAY
  },
});

Clarinet.test({
  name: "Can generate weekly insights with correct streak",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    // Simulate two weeks of entries
    let blocks = [];
    for(let i = 0; i < 14; i++) {
      blocks.push(chain.mineBlock([
        Tx.contractCall('zen_grid', 'record-entry', [
          types.uint(3),
          types.some(types.utf8(`Day ${i} entry`))
        ], wallet1.address)
      ]));
      // Mine additional blocks to simulate next day
      chain.mineEmptyBlock(144);
    }
    
    let week1Insight = chain.mineBlock([
      Tx.contractCall('zen_grid', 'generate-weekly-insight', [], wallet1.address)
    ]);
    
    let week2Insight = chain.mineBlock([
      Tx.contractCall('zen_grid', 'generate-weekly-insight', [], wallet1.address)
    ]);
    
    week1Insight.receipts[0].result.expectOk();
    week2Insight.receipts[0].result.expectOk();
    
    // Get the insight to verify streak
    let result = chain.callReadOnlyFn(
      'zen_grid',
      'get-current-week-insight',
      [types.principal(wallet1.address)],
      wallet1.address
    );
    
    assertEquals(result.result.expectSome().streak, types.uint(2));
  },
});

Clarinet.test({
  name: "Cannot generate insights without entries",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('zen_grid', 'generate-weekly-insight', [], wallet1.address)
    ]);
    
    block.receipts[0].result.expectErr(types.uint(104)); // ERR-NO-ENTRIES
  },
});
