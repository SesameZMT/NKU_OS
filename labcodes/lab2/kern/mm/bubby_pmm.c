// #include <pmm.h>
// #include <list.h>
// #include <string.h>
// #include <buddy_pmm.h>
// #include <stdio.h>

// #define MAX_ORDER 11
// #define MAX_PROVERTY 0
// // 在memlayout.h中可以找到相关定义
// // 数组大小为11，意味着页面大小为2^0到2^10
// free_area_t free_area[MAX_ORDER];

// static void
// buddy_init(void) {
//     for(int i = 0;i < MAX_ORDER;i++)
//     {
//         list_init(&(free_area[i].free_list));
//         free_area[i].nr_free = 0;
//     }
// }

// // 初始化时就按照对应的页面大小分块
// static void
// buddy_init_memmap(struct Page *base, size_t n) {
//     assert(n > 0);
//     struct Page *p = base;
//     size_t n1 = n;
//     for (; p != base + n; p ++) {
//         assert(PageReserved(p));
//         p->flags = 0;
//         p->property = 0;
//         set_page_ref(p, 0);
//     }
//     int order = MAX_ORDER - 1
//     while(n1 != 0)
//     {
//         int page_property = (1 << order);
//         if(page_property > MAX_PROVERTY)
//         {
//             MAX_PROVERTY = page_property;
//         }
//         if(n1 >= page_property)
//         {
//             p->property = page_property;
//             SetPageProperty(p);
//             unsigned int nr_free = free_area[order].nr_free;
//             list_entry_t list_entry = free_area[order].list_entry;
//             nr_free += page_property;
//             if (list_empty(&free_list)) {
//                 list_add(&free_list, &(p->page_link));
//             } else {
//                 list_entry_t* le = &free_list;
//                 while ((le = list_next(le)) != &free_list) {
//                     struct Page* page = le2page(le, page_link);
//                     if (p < page)
//                     {
//                         list_add_before(&(page->page_link),&(p->page_link));
//                         break;
//                     }
//                     if (list_next(le) == &free_list)
//                     {
//                         list_add_after(&(page->page_link),&(p->page_link));
//                     }
//                 }
//             }
//             n1 -= page_property;
//             p = p + page_property;
//         }
//         else
//         {
//             order -= 1;
//         }
//     }
// }

// static struct Page *
// buddy_alloc_pages(size_t n) {
//     assert(n > 0);
//     if (n > MAX_PROVERTY) {
//         return NULL;
//     }

//     int order = 0;
//     for(int i = 0;i < MAX_ORDER;i++)
//     {
//         if(n <= (1 << i))
//         {
//             order = i;
//             break;
//         }
//     }

//     struct Page *page = NULL;
//     list_entry_t *le = &(free_area[order].free_list);
//     while(n <= free_area[order].property/2)
//     {
//         struct Page *page p1 = free_area[order];
//         struct Page *page p2 = free_area[order] + free_area[order].property/2;
//         p1->property = free_area[order].property/2;
//         p2->property = free_area[order].property/2;
//         SetPageProperty(p2);
//     }
//     if(n > free_area[order].property/2)
//     {
//         page = le2page(le, page_link);
//         return page;
//     }
//     else
//     {

//     }
//     while ((le = list_next(le)) != &free_list) {
//         struct Page *p = le2page(le, page_link);
//         if (p->property >= n && min_size > p->property) {
//             page = p;
//             min_size = p->property;
//         }
//     }

//     if (page != NULL) {
//         list_entry_t* prev = list_prev(&(page->page_link));
//         list_del(&(page->page_link));
//         if (page->property > n) {
//             struct Page *p = page + n;
//             p->property = page->property - n;
//             SetPageProperty(p);
//             list_add(prev, &(p->page_link));
//         }
//         nr_free -= n;
//         ClearPageProperty(page);
//     }
//     return page;
// }

// static void
// best_fit_free_pages(struct Page *base, size_t n) {
//     assert(n > 0);
//     struct Page *p = base;
//     for (; p != base + n; p ++) {
//         assert(!PageReserved(p) && !PageProperty(p));
//         p->flags = 0;
//         set_page_ref(p, 0);
//     }
//     /*LAB2 EXERCISE 2: YOUR 2111454*/ 
//     // 编写代码
//     // 具体来说就是设置当前页块的属性为释放的页块数、并将当前页块标记为已分配状态、最后增加nr_free的值
//     base->property = n;
//     SetPageProperty(base);
//     nr_free += n;

//     if (list_empty(&free_list)) {
//         list_add(&free_list, &(base->page_link));
//     } else {
//         list_entry_t* le = &free_list;
//         while ((le = list_next(le)) != &free_list) {
//             struct Page* page = le2page(le, page_link);
//             if (base < page) {
//                 list_add_before(le, &(base->page_link));
//                 break;
//             } else if (list_next(le) == &free_list) {
//                 list_add(le, &(base->page_link));
//             }
//         }
//     }

//     list_entry_t* le = list_prev(&(base->page_link));
//     if (le != &free_list) {
//         p = le2page(le, page_link);
//         /*LAB2 EXERCISE 2: 2111454*/ 
//          // 编写代码
//         // 1、判断前面的空闲页块是否与当前页块是连续的，如果是连续的，则将当前页块合并到前面的空闲页块中
//         // 2、首先更新前一个空闲页块的大小，加上当前页块的大小
//         // 3、清除当前页块的属性标记，表示不再是空闲页块
//         // 4、从链表中删除当前页块
//         // 5、将指针指向前一个空闲页块，以便继续检查合并后的连续空闲页块
//         if(p + p->property == base)
//         {
//             p->property += base->property;
//             ClearPageProperty(base);
//             list_del(&(base->page_link));
//             base = p;
//         }
//     }

//     le = list_next(&(base->page_link));
//     if (le != &free_list) {
//         p = le2page(le, page_link);
//         if (base + base->property == p) {
//             base->property += p->property;
//             ClearPageProperty(p);
//             list_del(&(p->page_link));
//         }
//     }
// }

// static size_t
// best_fit_nr_free_pages(void) {
//     return nr_free;
// }

// static void
// basic_check(void) {
//     struct Page *p0, *p1, *p2;
//     p0 = p1 = p2 = NULL;
//     assert((p0 = alloc_page()) != NULL);
//     assert((p1 = alloc_page()) != NULL);
//     assert((p2 = alloc_page()) != NULL);

//     assert(p0 != p1 && p0 != p2 && p1 != p2);
//     assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

//     assert(page2pa(p0) < npage * PGSIZE);
//     assert(page2pa(p1) < npage * PGSIZE);
//     assert(page2pa(p2) < npage * PGSIZE);

//     list_entry_t free_list_store = free_list;
//     list_init(&free_list);
//     assert(list_empty(&free_list));

//     unsigned int nr_free_store = nr_free;
//     nr_free = 0;

//     assert(alloc_page() == NULL);

//     free_page(p0);
//     free_page(p1);
//     free_page(p2);
//     assert(nr_free == 3);

//     assert((p0 = alloc_page()) != NULL);
//     assert((p1 = alloc_page()) != NULL);
//     assert((p2 = alloc_page()) != NULL);

//     assert(alloc_page() == NULL);

//     free_page(p0);
//     assert(!list_empty(&free_list));

//     struct Page *p;
//     assert((p = alloc_page()) == p0);
//     assert(alloc_page() == NULL);

//     assert(nr_free == 0);
//     free_list = free_list_store;
//     nr_free = nr_free_store;

//     free_page(p);
//     free_page(p1);
//     free_page(p2);
// }

// // LAB2: below code is used to check the best fit allocation algorithm 
// // NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
// static void
// best_fit_check(void) {
//     int score = 0 ,sumscore = 6;
//     int count = 0, total = 0;
//     list_entry_t *le = &free_list;
//     while ((le = list_next(le)) != &free_list) {
//         struct Page *p = le2page(le, page_link);
//         assert(PageProperty(p));
//         count ++, total += p->property;
//     }
//     assert(total == nr_free_pages());

//     basic_check();

//     #ifdef ucore_test
//     score += 1;
//     cprintf("grading: %d / %d points\n",score, sumscore);
//     #endif
//     struct Page *p0 = alloc_pages(5), *p1, *p2;
//     assert(p0 != NULL);
//     assert(!PageProperty(p0));

//     #ifdef ucore_test
//     score += 1;
//     cprintf("grading: %d / %d points\n",score, sumscore);
//     #endif
//     list_entry_t free_list_store = free_list;
//     list_init(&free_list);
//     assert(list_empty(&free_list));
//     assert(alloc_page() == NULL);

//     #ifdef ucore_test
//     score += 1;
//     cprintf("grading: %d / %d points\n",score, sumscore);
//     #endif
//     unsigned int nr_free_store = nr_free;
//     nr_free = 0;

//     // * - - * -
//     free_pages(p0 + 1, 2);
//     free_pages(p0 + 4, 1);
//     assert(alloc_pages(4) == NULL);
//     assert(PageProperty(p0 + 1) && p0[1].property == 2);
//     // * - - * *
//     assert((p1 = alloc_pages(1)) != NULL);
//     assert(alloc_pages(2) != NULL);      // best fit feature
//     assert(p0 + 4 == p1);

//     #ifdef ucore_test
//     score += 1;
//     cprintf("grading: %d / %d points\n",score, sumscore);
//     #endif
//     p2 = p0 + 1;
//     free_pages(p0, 5);
//     assert((p0 = alloc_pages(5)) != NULL);
//     assert(alloc_page() == NULL);

//     #ifdef ucore_test
//     score += 1;
//     cprintf("grading: %d / %d points\n",score, sumscore);
//     #endif
//     assert(nr_free == 0);
//     nr_free = nr_free_store;

//     free_list = free_list_store;
//     free_pages(p0, 5);

//     le = &free_list;
//     while ((le = list_next(le)) != &free_list) {
//         struct Page *p = le2page(le, page_link);
//         count --, total -= p->property;
//     }
//     assert(count == 0);
//     assert(total == 0);
//     #ifdef ucore_test
//     score += 1;
//     cprintf("grading: %d / %d points\n",score, sumscore);
//     #endif
// }
// // //这个结构体在
// // const struct pmm_manager best_fit_pmm_manager = {
// //     .name = "best_fit_pmm_manager",
// //     .init = best_fit_init,
// //     .init_memmap = best_fit_init_memmap,
// //     .alloc_pages = best_fit_alloc_pages,
// //     .free_pages = best_fit_free_pages,
// //     .nr_free_pages = best_fit_nr_free_pages,
// //     .check = best_fit_check,
// // };

