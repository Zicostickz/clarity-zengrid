import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Weekly insights correctly aggregate entries",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    // Record entries for a week
    for(let i = 0; i < 7; i++) {
      let block = chain.mineBlock([
        Tx.contractCall('zen_grid', 'record-entry', [
          types.uint(3),
          types.some(types.utf8(`Day ${i} entry`))
        ], wallet1.address)
      ]);
      chain.mineEmptyBlock(144); // Next day
    }
    
    let insightBlock = chain.mineBlock([
      Tx.contractCall('zen_grid', 'generate-weekly-insight', [], wallet1.address)
    ]);
    
    insightBlock.receipts[0].result.expectOk();
    
    let insight = chain.callReadOnlyFn(
      'zen_grid',
      'get-current-week-insight',
      [types.principal(wallet1.address)],
      wallet1.address
    );
    
    let someInsight = insight.result.expectSome();
    assertEquals(someInsight.entry_count, types.uint(7));
    assertEquals(someInsight.avg_score, types.uint(3));
  },
});

Clarinet.test({
  name: "Streak breaks when days are missed",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    // Record entries for 6 days (missing one)
    for(let i = 0; i < 6; i++) {
      let block = chain.mineBlock([
        Tx.contractCall('zen_grid', 'record-entry', [
          types.uint(3),
          types.some(types.utf8(`Day ${i} entry`))
        ], wallet1.address)
      ]);
      chain.mineEmptyBlock(144);
    }
    
    let insightBlock = chain.mineBlock([
      Tx.contractCall('zen_grid', 'generate-weekly-insight', [], wallet1.address)
    ]);
    
    let insight = chain.callReadOnlyFn(
      'zen_grid',
      'get-current-week-insight',
      [types.principal(wallet1.address)],
      wallet1.address
    );
    
    let someInsight = insight.result.expectSome();
    assertEquals(someInsight.streak, types.uint(1));
  },
});
